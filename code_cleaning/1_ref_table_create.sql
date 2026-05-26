
-- STEP 1: Create reference IDs for unique combinations of: violation_code, violation_description, fine_amount
-- violation_reference_id = -999 when violation_code = 000
SELECT 'creating new table by adding reference IDs and saving new, and saving new table to data/parking_clean_with_reference.parque  '
COPY (

    SELECT
        *,

        DENSE_RANK() OVER (
            ORDER BY
                violation_code,
                violation_description,
                fine_amount
        ) AS violation_reference_id

    FROM read_parquet('data/parking_clean.parquet')

    WHERE TRIM(violation_code) <> '000'

    UNION ALL

    SELECT
        *,

        -999 AS violation_reference_id

    FROM read_parquet('data/parking_clean.parquet')

    WHERE TRIM(violation_code) = '000'
)
TO 'data/parking_clean_with_reference.parquet'
(FORMAT PARQUET);


-- STEP 2: creating reference table data/violation_reference.csv.
SELECT 'creating small reference table  saving to data/violation_reference.csv'
COPY (
    SELECT
        violation_reference_id,
        violation_code,
        violation_description,
        fine_amount,

        COUNT(*) AS occurrence
    FROM read_parquet('data/parking_clean_with_reference.parquet')
    WHERE violation_reference_id <> -999
    GROUP BY
        violation_reference_id,
        violation_code,
        violation_description,
        fine_amount
)
TO 'data/violation_reference.csv'
(HEADER, DELIMITER ',');


-- STEP 3: adding correction columns, frequency_group column, correction type
SELECT 'adding correction columns, frequency_group column, correction type to data/violation_reference.csv'
CREATE TEMP TABLE temp_reference AS
SELECT
    *,
    violation_code AS code_corrected,
    violation_description AS desc_corrected,
    fine_amount AS fine_corrected,
    CAST(NULL AS VARCHAR) AS correction_type,

    CASE
    WHEN occurrence = 1
        THEN 'singleton'
    WHEN occurrence BETWEEN 2 AND 20
        THEN 'rare'
    WHEN occurrence BETWEEN 21 AND 500
        THEN 'rare_medium'
    WHEN occurrence BETWEEN 501 AND 50000
        THEN 'less_frequent'
    ELSE 'dominant'
    END AS frequency_group
FROM read_csv_auto('data/violation_reference.csv');

-- Saving
COPY temp_reference
TO 'data/violation_reference.csv'
(HEADER, DELIMITER ',');

-- Remove temporary table
DROP TABLE temp_reference;