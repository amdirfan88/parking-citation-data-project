-- STEP 1: Create reference IDs for unique combinations of: violation_code, violation_description, fine_amount
-- violation_reference_id = -999 when violation_code = 000

SELECT 'preparing data for correction stage by adding reference IDs';

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
SELECT 'creating small reference table  saving to data/violation_reference.csv';
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