-- Star schema for dashboarding
-- Source: data/parking_clean_transformer_semantic_cluster.parquet

CREATE SCHEMA IF NOT EXISTS parking_dw;

CREATE OR REPLACE TEMP VIEW stg_citations AS
SELECT
    ticket_number,
    issue_date,
    issue_time,
    agency,
    agency_desc,
    violation_reference_id,
    violation_code,
    violation_description,
    fine_amount
FROM read_parquet('data/parking_clean_transformer_semantic_cluster.parquet');


-- ----------------------------
-- Dimension tables
-- ----------------------------

CREATE OR REPLACE TABLE parking_dw.dim_date AS
SELECT DISTINCT
    CAST(issue_date AS DATE) AS date_key,
    year(issue_date) AS year,
    quarter(issue_date) AS quarter,
    month(issue_date) AS month_num,
    monthname(issue_date) AS month_name,
    week(issue_date) AS week_num,
    day(issue_date) AS day_num,
    dayname(issue_date) AS weekday_name,
    dayofweek(issue_date) AS weekday_num,
    CASE
        WHEN dayofweek(issue_date) IN (0, 6) THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type
FROM stg_citations;

CREATE OR REPLACE TABLE parking_dw.dim_violation AS
SELECT DISTINCT
    violation_reference_id AS violation_key,
    violation_code,
    violation_description
FROM stg_citations
WHERE violation_reference_id IS NOT NULL;

CREATE OR REPLACE TABLE parking_dw.dim_agency AS
SELECT DISTINCT
    agency AS agency_key,
    agency_desc
FROM stg_citations;

-- ----------------------------
-- Fact table (ticket-level grain)
-- ----------------------------

CREATE OR REPLACE TABLE parking_dw.fact_citation AS
SELECT
    ticket_number,
    CAST(issue_date AS DATE) AS date_key,
    violation_reference_id AS violation_key,
    agency AS agency_key,
    TRY_CAST(fine_amount AS DOUBLE) AS fine_amount,
    1 AS citation_count
FROM stg_citations;


-- ----------------------------
-- Export to CSV for dashboarding
-- Destination is `data/dashboard_exports/` inside the repo.
-- ----------------------------

COPY parking_dw.dim_date
TO 'data/dashboard_exports/dim_date.csv'
(HEADER, DELIMITER ',');

COPY parking_dw.dim_violation
TO 'data/dashboard_exports/dim_violation.csv'
(HEADER, DELIMITER ',');

COPY parking_dw.dim_agency
TO 'data/dashboard_exports/dim_agency.csv'
(HEADER, DELIMITER ',');

COPY parking_dw.fact_citation
TO 'data/dashboard_exports/fact_citation.csv'
(HEADER, DELIMITER ',');
