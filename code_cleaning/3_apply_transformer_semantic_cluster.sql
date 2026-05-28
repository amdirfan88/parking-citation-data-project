-- Apply Transformer-assisted semantic cluster corrections to the full parking dataset.
-- Joins by violation_reference_id and updates:
--   violation_code <- code_corrected
--   violation_description <- desc_corrected
--   fine_amount <- fine_corrected

SELECT 'joining corrected reference CSV to parking_clean_with_reference.parquet and writing cleaned parquet';

COPY (
    SELECT
        p.* EXCLUDE (violation_code, violation_description, fine_amount),
        COALESCE(NULLIF(TRIM(c.code_corrected), ''), p.violation_code) AS violation_code,
        COALESCE(NULLIF(TRIM(c.desc_corrected), ''), p.violation_description) AS violation_description,
        COALESCE(TRY_CAST(c.fine_corrected AS DOUBLE), p.fine_amount) AS fine_amount
    FROM read_parquet('data/parking_clean_with_reference.parquet') AS p
    LEFT JOIN read_csv_auto('data/Transformer-assist_Semantic_Cluster.csv') AS c
        ON p.violation_reference_id = c.violation_reference_id
)
TO 'data/parking_clean_transformer_semantic_cluster.parquet'
(FORMAT PARQUET);
