-- ============================================================
-- Parking-data preprocessing using one DuckDB working table
-- ============================================================

BEGIN TRANSACTION;


-- ------------------------------------------------------------
-- 1. Create one working table
--    - Keep required columns
--    - Remove exact duplicate rows
-- ------------------------------------------------------------

SELECT '-- Creating working table and removing exact duplicates --';

-- Step 1: Remove exact duplicate full rows
CREATE OR REPLACE TABLE preprocess_table AS
SELECT DISTINCT *
FROM read_parquet('data/parking_raw.parquet');


-- Step 2: Remove unwanted columns from preprocess_table
ALTER TABLE preprocess_table DROP COLUMN meter_id;
ALTER TABLE preprocess_table DROP COLUMN marked_time;
ALTER TABLE preprocess_table DROP COLUMN plate_expiry_date;
ALTER TABLE preprocess_table DROP COLUMN vin;
ALTER TABLE preprocess_table DROP COLUMN make;
ALTER TABLE preprocess_table DROP COLUMN color;
ALTER TABLE preprocess_table DROP COLUMN route;
ALTER TABLE preprocess_table DROP COLUMN color_desc;
ALTER TABLE preprocess_table DROP COLUMN geocodelocation;


-- ------------------------------------------------------------
-- 2. Fail if ticket_number is duplicated
-- ------------------------------------------------------------

SELECT
    CASE
        WHEN COUNT(*) > 0
            THEN error(
                'Duplicate ticket_number found after exact-row deduplication'
            )
        ELSE 'Validation passed: ticket_number is unique'
    END AS validation_result
FROM (
    SELECT ticket_number
    FROM preprocess_table
    GROUP BY ticket_number
    HAVING COUNT(*) > 1
) AS duplicated_tickets;


-- ------------------------------------------------------------
-- 3. Delete rows dated before January 1, 2014
-- ------------------------------------------------------------

SELECT '-- Deleting rows before 2014 --';

DELETE FROM preprocess_table
WHERE issue_date < DATE '2014-01-01';


-- ------------------------------------------------------------
-- 4. Delete rows after the last reliable issue date
--
-- A date is considered reliable when it has more than
-- 1,000 tickets.
-- ------------------------------------------------------------

SELECT '-- Deleting rows with invalid future dates --';

DELETE FROM preprocess_table
WHERE issue_date > (
    SELECT MAX(issue_date)
    FROM (
        SELECT issue_date
        FROM preprocess_table
        GROUP BY issue_date
        HAVING COUNT(*) > 1000
    ) AS reliable_dates
);


-- ------------------------------------------------------------
-- 5. Delete rows with missing or invalid issue times
--
-- Valid HHMM examples:
--     0     = 00:00
--     5     = 00:05
--     930   = 09:30
--     2359  = 23:59
-- ------------------------------------------------------------

SELECT '-- Deleting missing and invalid issue times --';

DELETE FROM preprocess_table
WHERE issue_time IS NULL
   OR issue_time < 0
   OR FLOOR(issue_time / 100.0) >= 24
   OR issue_time % 100 >= 60;


-- ------------------------------------------------------------
-- 6. Add issue_datetime to the existing table
-- ------------------------------------------------------------

SELECT '-- Creating issue_datetime --';

ALTER TABLE preprocess_table
ADD COLUMN issue_datetime TIMESTAMP;


-- Populate the new timestamp column

UPDATE preprocess_table
SET issue_datetime =
    CAST(
        strptime(
            strftime(issue_date, '%Y-%m-%d')
            || ' '
            || LPAD(
                CAST(
                    CAST(FLOOR(issue_time / 100.0) AS BIGINT)
                    AS VARCHAR
                ),
                2,
                '0'
            )
            || ':'
            || LPAD(
                CAST(
                    CAST(issue_time % 100 AS BIGINT)
                    AS VARCHAR
                ),
                2,
                '0'
            )
            || ':00',
            '%Y-%m-%d %H:%M:%S'
        )
        AS TIMESTAMP
    );


-- The original date and time columns are no longer needed

ALTER TABLE preprocess_table DROP COLUMN issue_date;
ALTER TABLE preprocess_table DROP COLUMN issue_time;


-- ------------------------------------------------------------
-- 9. Export only once after preprocessing is complete
-- ------------------------------------------------------------

COPY preprocess_table
TO 'data/parking_preprocessed.parquet'
(FORMAT PARQUET);