-- Limit DuckDB resource usage.
-- Adjust these values based on your computer.
SET memory_limit = '3GB';
SET threads = 3;
SET temp_directory = 'data/duckdb_temp';

SELECT 'creating violation reference table';

-- STEP 1:
-- Extract only unique violation combinations first.
CREATE OR REPLACE TEMP TABLE violation_reference AS
SELECT
    ROW_NUMBER() OVER (
        ORDER BY
            violation_code,
            violation_description,
            fine_amount
    ) AS violation_reference_id,

    violation_code,
    violation_description,
    fine_amount,
    occurrence
FROM (
    SELECT
        violation_code,
        violation_description,
        fine_amount,
        COUNT(*) AS occurrence
    FROM read_parquet('data/parking_preprocessed.parquet')
    WHERE TRIM(violation_code) <> '000'
    GROUP BY
        violation_code,
        violation_description,
        fine_amount
);

-- STEP 2:
-- Save the small reference table.
COPY violation_reference
TO 'data/violation_reference.csv'
(
    HEADER,
    DELIMITER ','
);

SELECT 'adding reference IDs to parking data';

-- STEP 3:
-- Join the reference IDs back to the full dataset.
COPY (
    SELECT
        p.*,

        CASE
            WHEN TRIM(p.violation_code) = '000' THEN -999
            ELSE r.violation_reference_id
        END AS violation_reference_id

    FROM read_parquet('data/parking_preprocessed.parquet') AS p

    LEFT JOIN violation_reference AS r
        ON p.violation_code IS NOT DISTINCT FROM r.violation_code
       AND p.violation_description
            IS NOT DISTINCT FROM r.violation_description
       AND p.fine_amount
            IS NOT DISTINCT FROM r.fine_amount
)
TO 'data/parking_with_reference.parquet'
(
    FORMAT PARQUET,
    COMPRESSION ZSTD
);