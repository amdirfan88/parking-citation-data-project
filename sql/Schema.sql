CREATE OR REPLACE TABLE dim_date AS
SELECT DISTINCT
    CAST(issue_datetime AS DATE)                    AS date_key,
    
    year(issue_datetime)                            AS year,
    quarter(issue_datetime)                         AS quarter,
    month(issue_datetime)                           AS month_num,
    monthname(issue_datetime)                       AS month_name,
    
    week(issue_datetime)                            AS week_num,
    
    day(issue_datetime)                             AS day_num,
    dayname(issue_datetime)                         AS weekday_name,
    
    dayofweek(issue_datetime)                       AS weekday_num,
    
    CASE
        WHEN dayofweek(issue_datetime) IN (0, 6)
        THEN 'Weekend'
        ELSE 'Weekday'
    END                                             AS day_type

FROM read_parquet('parking_clean.parquet');

CREATE OR REPLACE TABLE dim_violation AS
SELECT DISTINCT
    violation_code,
    violation_description

FROM read_parquet('parking_clean.parquet');