# LA Parking Citation Data Engineering Project

## Overview

This project builds a reproducible data engineering and predictive analytics pipeline using the Los Angeles City Parking Citation dataset.

The current scope of the project focuses on:

- Data cleaning
- Data validation
- Data transformation
- Parquet-based analytical storage
- SQL-driven ETL workflows
- Data warehousing preparation
- Dashboard-ready aggregated datasets

---

## Predictive and Forecasting Analytics

Planned analytical modeling includes:

- Citation volume forecasting by agency
- Revenue forecasting from parking citations
- Temporal trend analysis by violation type
- Spatiotemporal hotspot analysis
- Violation pattern detection across time and location
- Agency-level enforcement trend modeling

Potential methods include:

- Time-series forecasting
- Statistical modeling
- Machine learning models
- Spatiotemporal analytics
---

## Dataset

Source:
LA City Open Data – Parking Citations

Main dataset contains parking citation records including:

- Ticket information
- Citation issue date and time
- Vehicle attributes
- Violation types
- Enforcement agencies
- Fine amounts

---

## Selected Variables

The project currently keeps the following variables:

| Variable | Description |
|---|---|
| ticket_number | Unique citation ID |
| issue_date | Citation issue date |
| issue_time | Citation issue time |
| rp_state_plate | Vehicle plate |
| body_style | Vehicle body style |
| agency | Enforcement agency code |
| violation_code | Parking violation code |
| violation_description | Parking violation description |
| fine_amount | Citation fine amount |
| agency_desc | Enforcement agency description |
| body_style_desc | Vehicle body style description |

---

## Tech Stack

| Component | Tool |
|---|---|
| Query Engine | DuckDB |
| Storage Format | Parquet |
| SQL Execution | DuckDB CLI |
| Version Control | Git + GitHub |
| Future Dashboarding | Power BI / Tableau |
| Future GIS | ArcGIS |

---

## Project Structure

```text
parking-citation-data-project/
│
├── sql/
│   ├── clean_parking.sql
│
├── data/
│   ├── parking_raw.parquet
│   ├── parking_clean.parquet
│
├── docs/
├── notebooks/
├── src/
├── tests/
│
├── README.md
├── pyproject.toml
└── uv.lock