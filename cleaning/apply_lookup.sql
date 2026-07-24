-- Apply violation correction lookup values to the full parking dataset.
-- Joins by violation_reference_id and updates:
--   violation_code <- code_corrected
--   violation_description <- desc_corrected
--   fine_amount <- fine_corrected
-- If no correction is available for a row, keep the original value.

SELECT 'joining corrected reference CSV to parking_with_reference.parquet and writing cleaned parquet';

COPY (
    SELECT
        p.* EXCLUDE (violation_code, violation_description, fine_amount, agency, agency_desc),

        CASE
            WHEN c.violation_reference_id IS NOT NULL
                THEN COALESCE(NULLIF(TRIM(c.code_corrected), ''), p.violation_code)
            ELSE p.violation_code
        END AS violation_code,

        CASE
            WHEN c.violation_reference_id IS NOT NULL
                THEN COALESCE(NULLIF(TRIM(c.desc_corrected), ''), p.violation_description)
            ELSE 'Others'
        END AS violation_description,

        CASE
            WHEN c.violation_reference_id IS NOT NULL
                THEN COALESCE(TRY_CAST(c.fine_corrected AS DOUBLE), p.fine_amount)
            ELSE COALESCE(p.fine_amount, 0)
        END AS fine_amount,

        COALESCE(p.agency, -999) AS agency,
        COALESCE(NULLIF(TRIM(p.agency_desc), ''), 'missing description') AS agency_desc

    FROM read_parquet('data/parking_with_reference.parquet') AS p

    LEFT JOIN read_csv_auto('data/violation_correction_lookup.csv') AS c
        ON p.violation_reference_id = c.violation_reference_id
)
TO 'data/violation_cleaned.parquet'
(FORMAT PARQUET);
