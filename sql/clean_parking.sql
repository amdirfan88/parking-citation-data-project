-- 1) keep only needed columns and remove duplicate full rows
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

-- 2) fail if ticket_number is duplicated
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

-- 3) drop rows before 2014 by overwriting same file
COPY (
    SELECT *
    FROM read_parquet('data/parking_clean.parquet')
    WHERE issue_date >= DATE '2014-01-01'
) TO 'data/parking_clean.parquet' (FORMAT PARQUET);

COPY (
    SELECT *
    FROM read_parquet('data/parking_clean.parquet')
    WHERE issue_date <= (
        SELECT MAX(issue_date)
        FROM (
            SELECT
                issue_date,
                COUNT(*) AS n_tickets
            FROM read_parquet('data/parking_clean.parquet')
            GROUP BY issue_date
            HAVING COUNT(*) > 1000
        )
    )
) TO 'data/parking_clean.parquet' (FORMAT PARQUET);

COPY (
    SELECT *
    FROM read_parquet('data/parking_clean.parquet')
    WHERE issue_date <= (
        SELECT MAX(issue_date)
        FROM (
            SELECT
                issue_date,
                COUNT(*) AS n_tickets
            FROM read_parquet('data/parking_clean.parquet')
            GROUP BY issue_date
            HAVING COUNT(*) > 1000
        )
    )
) TO 'data/parking_clean.parquet' (FORMAT PARQUET);