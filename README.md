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
- Transformer-assisted semantic clustering to canonicalize violation fields

---

## Predictive and Forecasting Analytics

Planned analytical modeling includes:

- Citation volume forecasting by agency
- Revenue forecasting from parking citations
- Temporal trend analysis by violation type

Potential methods include:

- Time-series forecasting

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


---

## Project Structure


<!-- PROJECT_TREE_START -->
```text
parking-citation-data-project/
├── bash_cheatsheet.md
├── bash_scripts
│   ├── download_chunks.sh
│   └── update_tree.sh
├── code_cleaning
│   ├── 1_ref_table_create.sql
│   ├── 2_ML_engineering_citation.py
│   ├── 3_apply_transformer_semantic_cluster.sql
│   ├── cleaning_utils.py
│   └── README.md
├── config
│   └── airflow.cfg
├── creating_symbolic-link.md
├── dags
│   └── parking_pipeline.py
├── dashboards
│   └── powerbi
├── data
│   ├── blank_entries_with_cluster.csv
│   ├── chunks
│   ├── dashboard_exports
│   ├── data_exports -> /Users/taniazamansarna/OneDrive - Arizona State University/parking-citation-analytics
│   ├── dim_agency.csv
│   ├── dim_body_style.csv
│   ├── dim_date.csv
│   ├── dim_state.csv
│   ├── dim_violation.csv
│   ├── fact_citation.csv
│   ├── low_freq_entries_with_cluster.csv
│   ├── Transformer-assist_Semantic_Cluster.csv
│   ├── violation_reference_1.csv
│   ├── violation_reference_2.csv
│   ├── violation_reference.csv
│   └── zero_fine_entries_with_cluster.csv
├── data_exports -> /Users/taniazamansarna/Library/CloudStorage/OneDrive-ArizonaStateUniversity/parking-citation-analytics
├── Data_Project.docx
├── docker-compose.yaml
├── docs_operational_analytics
│   ├── dashboard_design.md
│   ├── data_health_report.md
│   ├── data_wrangling.md
│   ├── etl_pipeline.md
│   ├── findings_summary.md
│   ├── gis_analysis.md
│   ├── methodology.md
│   ├── project_objective.md
│   └── warehousing_schema.md
├── fact-dim-table_n_dashboard
│   ├── dashboard_views.sql
│   └── schema.sql
├── logs
│   ├── dag_id=parking_pipeline
│   └── dag_processor
├── main.py
├── notebooks
│   ├── Clustering.ipynb
│   ├── Compare_dameraul.ipynb
│   ├── Compare_LLM.ipynb
│   ├── comparison_scores_LLM.csv
│   └── comparison_scores.csv
├── project_structure.txt
├── pyproject.toml
├── README_tmp.md
├── README.md
├── sql
│   ├── build_csv.sql
│   ├── build_parquet.sql
│   └── clean_parking.sql
├── system_requirements.md
├── Things_to_do.md
└── uv.lock
```
<!-- PROJECT_TREE_END -->
