-- 1) drop rows before 2014 
SELECT '--drop rows before 2014--';
COPY (
    SELECT *
    FROM read_parquet('data/parking_clean.parquet')
    WHERE issue_date >= DATE '2014-01-01'
) TO 'data/parking_clean.parquet' (FORMAT PARQUET);

-- 2) drop rows after the date corresponds to recently added

SELECT '--drop rows corresponds to future wrong date--';
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

SELECT '--Deleting null time--';

COPY (
    SELECT *
    FROM read_parquet('data/parking_clean.parquet')
    WHERE issue_time IS NOT NULL
) TO 'data/parking_clean.parquet' (FORMAT PARQUET);


SELECT '--Combining date and time into a single timestamp--';

COPY (
    SELECT
        * EXCLUDE (issue_date, issue_time),
        CAST(
            strptime(
                strftime(issue_date, '%Y-%m-%d') || ' ' ||
                LPAD(CAST(CAST(FLOOR(issue_time / 100.0) AS BIGINT) AS VARCHAR), 2, '0') || ':' ||
                LPAD(CAST(CAST(issue_time % 100 AS BIGINT) AS VARCHAR), 2, '0') || ':00',
                '%Y-%m-%d %H:%M:%S'
            ) AS TIMESTAMP
        ) AS issue_datetime
    FROM read_parquet('data/parking_clean.parquet')
    WHERE issue_time IS NOT NULL
      AND issue_time % 100 < 60
      AND FLOOR(issue_time / 100.0) < 24
) TO 'data/parking_clean.parquet' (FORMAT PARQUET);