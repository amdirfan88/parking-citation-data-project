WITH parsed AS (
    SELECT
        loc_lat,
        loc_long,
        geocodelocation,
        TRY_CAST(
            regexp_extract(
                geocodelocation,
                '^POINT \((-?[0-9.]+) (-?[0-9.]+)\)$',
                1
            ) AS DOUBLE
        ) AS point_long,
        TRY_CAST(
            regexp_extract(
                geocodelocation,
                '^POINT \((-?[0-9.]+) (-?[0-9.]+)\)$',
                2
            ) AS DOUBLE
        ) AS point_lat
    FROM 'data/violation_cleaned.parquet'
    WHERE loc_lat IS NOT NULL
      AND loc_long IS NOT NULL
      AND geocodelocation IS NOT NULL
)
SELECT COUNT(*) AS inconsistent_rows
FROM parsed
WHERE point_long IS NULL
   OR point_lat IS NULL
   OR ABS(loc_long - point_long) > 1e-9
   OR ABS(loc_lat - point_lat) > 1e-9;





COPY (
             SELECT *
             FROM 'data/violation_cleaned.parquet'
             WHERE issue_datetime >= (
                 SELECT MAX(issue_datetime) - INTERVAL 30 DAY
                 FROM 'data/violation_cleaned.parquet'
             )
         )
         TO 'data/last_30_days.csv'
         (
             HEADER,
             DELIMITER ','
         );


COPY (
    SELECT * EXCLUDE (location, geocodelocation, agency)
    FROM read_parquet('data/violation_cleaned.parquet')
    WHERE DATE(issue_datetime) = (
        SELECT MAX(DATE(issue_datetime))
        FROM read_parquet('data/violation_cleaned.parquet')
    )
) TO 'data/for_GIS.csv' (HEADER, DELIMITER ',');