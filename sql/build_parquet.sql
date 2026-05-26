-- Merging chunks to crete parking_raw.parquet----

SELECT '-- merging chunks ----';

COPY (
    SELECT *
    FROM read_csv_auto(
        'data/chunks/*.csv',
        files_to_sniff = -1,
        types = {
            'ticket_number': VARCHAR,
            'fine_amount': DOUBLE
        }
    )
)
TO 'data/parking_raw.parquet'
(FORMAT PARQUET);


-- keep only needed columns and remove duplicate full rows

SELECT '-- removing duplicate entries and unnecessary column ----';

COPY (
    SELECT DISTINCT
        ticket_number,
        issue_date,
        issue_time,
        rp_state_plate,
        body_style,
        agency,
        violation_code,
        violation_description,
        fine_amount,
        agency_desc,
        body_style_desc
    FROM read_parquet('data/parking_raw.parquet')
) TO 'data/parking_clean.parquet' (FORMAT PARQUET);

--  fail if ticket_number is duplicated
WITH dupes AS (
    SELECT
        ticket_number,
        COUNT(*) AS n
    FROM read_parquet('data/parking_clean.parquet')
    GROUP BY ticket_number
    HAVING COUNT(*) > 1
)
SELECT
    CASE
        WHEN COUNT(*) > 0 THEN error('Duplicate ticket_number found')
        ELSE 'Validation passed'
    END AS validation_result
FROM dupes;

-- Creating database [optional]
CREATE OR REPLACE TABLE parking_db AS
SELECT *
FROM read_parquet('data/parking_clean.parquet');