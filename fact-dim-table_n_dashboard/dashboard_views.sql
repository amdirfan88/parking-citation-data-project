-- =========================
-- Daily ticket distribution
-- =========================

COPY (
    SELECT
        CAST(issue_datetime AS DATE) AS issue_day,
        COUNT(*) AS n_tickets
    FROM read_parquet('data/parking_clean.parquet')
    GROUP BY issue_day
    ORDER BY issue_day
)
TO 'data/dashboard_daily_tickets.csv'
(FORMAT CSV, HEADER);


-- =========================
-- Agency distribution
-- =========================

COPY (
    SELECT
        agency_desc,
        COUNT(*) AS n_tickets,
        SUM(fine_amount) AS total_fine
    FROM read_parquet('data/parking_clean.parquet')
    GROUP BY agency_desc
    ORDER BY n_tickets DESC
)
TO 'data/dashboard_agency.csv'
(FORMAT CSV, HEADER);


-- =========================
-- Violation distribution
-- =========================

COPY (
    SELECT
        violation_description,
        COUNT(*) AS n_tickets,
        SUM(fine_amount) AS total_fine
    FROM read_parquet('data/parking_clean.parquet')
    GROUP BY violation_description
    ORDER BY n_tickets DESC
)
TO 'data/dashboard_violation.csv'
(FORMAT CSV, HEADER);


-- =========================
-- Body style distribution
-- =========================

COPY (
    SELECT
        body_style_desc,
        COUNT(*) AS n_tickets
    FROM read_parquet('data/parking_clean.parquet')
    GROUP BY body_style_desc
    ORDER BY n_tickets DESC
)
TO 'data/dashboard_body_style.csv'
(FORMAT CSV, HEADER);


-- =========================
-- State distribution
-- =========================

COPY (
    SELECT
        rp_state_plate,
        COUNT(*) AS n_tickets
    FROM read_parquet('data/parking_clean.parquet')
    GROUP BY rp_state_plate
    ORDER BY n_tickets DESC
)
TO 'data/dashboard_state.csv'
(FORMAT CSV, HEADER);