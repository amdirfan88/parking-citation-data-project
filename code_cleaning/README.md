# Code Cleaning Pipeline

This folder contains the violation-cleaning and correction workflow used to create transformer-assisted corrected citation data.

## Problem

Parking citations often contain many near-duplicate *violation definitions* that should be treated as the same thing for analytics:

- `violation_code` formatting drift (punctuation, extra characters, inconsistent spacing/case)
- `violation_description` spelling/typos/abbreviations (e.g., "NO PARK/STREET CLEAN" vs "NO PARK STREET CLEANING")
- `fine_amount` inconsistencies (missing/0/formatting differences)

If we aggregate dashboards directly on raw `violation_code` or `violation_description`, metrics fragment across many variants and the "top violations" views become noisy and misleading.

To fix that, this pipeline builds a stable `violation_reference_id` for each unique (code, description, fine) combination, then clusters similar references and produces corrected ("canonical") values that can be applied back to the full citation dataset.

## Method (How The Cleaning Works)

At a high level, we treat each row in `violation_reference.csv` as a node, compute pairwise similarity, and cluster nodes that represent the same real-world violation.

1. Build a reference set:
   - `violation_reference_id` is created from unique combinations of `(violation_code, violation_description, fine_amount)`.
   - A reference table (`data/violation_reference.csv`) is generated with `occurrence` counts (how frequent each reference appears).

2. Create "underprocess" working columns:
   - We copy the original values into `code_underprocess`, `desc_underprocess`, `fine_underprocess`.
   - We normalize code formatting (strip punctuation, trim, uppercase) and normalize description case/whitespace.

3. Similarity scoring (hybrid ML + string distance):
   - Code similarity: Damerau-Levenshtein normalized similarity (robust to transpositions/typos).
   - Description similarity:
     - RapidFuzz ratio for lexical similarity
     - Transformer sentence embedding similarity using `sentence-transformers/all-MiniLM-L6-v2` (semantic similarity)
   - Fine similarity: simple numeric agreement (within tolerance).
   - These components are combined into a normalized distance in `[0, 1]`.

4. Clustering:
   - DBSCAN is run using the precomputed distance matrix.
   - DBSCAN noise points (`-1`) are given unique cluster IDs so every row has a cluster label.

5. Handle excluded references:
   - References with blank fields, zero fines, or very low frequency are excluded from the main DBSCAN run.
   - They are assigned to the nearest existing cluster by computing distance to all clustered references.

6. Canonicalization ("corrected" values):
   - For each cluster, we pick field-by-field representatives based on highest `occurrence` **among non-blank values**:
     - `code_corrected` comes from the highest-occurrence non-blank code in the cluster
     - `desc_corrected` comes from the highest-occurrence non-blank description in the cluster
     - `fine_corrected` follows the rule in the clustering script (keep original for high-frequency rows unless blank, substitute for low-frequency rows)
   - This avoids propagating blanks even if the single highest-occurrence row is incomplete.

7. Apply corrections back to the full parquet:
   - Using `violation_reference_id`, the corrected reference CSV is left-joined to the full citation parquet
   - The three violation columns (`violation_code`, `violation_description`, `fine_amount`) are updated from corrected values when present.

## Files

- `1_ref_table_create.sql`
  - Builds `data/parking_clean_with_reference.parquet` by adding `violation_reference_id`.
  - Builds `data/violation_reference.csv` as the unique violation reference table.

- `cleaning_utils.py`
  - Helper functions used by ML clustering scripts:
    - preprocessing underprocess columns
    - split/filter helpers
    - nearest-cluster assignment for excluded rows

- `2_ML_engineering_citation.py`
  - Runs semantic clustering on the violation reference table.
  - Fills excluded rows (`blank`, `low frequency`, `zero fine`) via nearest-cluster assignment.
  - Canonicalizes corrected values by cluster.
  - Produces `data/Transformer-assist_Semantic_Cluster.csv`.

- `3_apply_transformer_semantic_cluster.sql`
  - Joins corrected reference CSV back to the full parquet using `violation_reference_id`.
  - Produces `data/parking_clean_transformer_semantic_cluster.parquet`.


## Recommended Run Order

1. Run `1_ref_table_create.sql`
2. Run `2_ML_engineering_citation.py`
3. Run `3_apply_transformer_semantic_cluster.sql`


## Main Outputs

- `data/parking_clean_with_reference.parquet`
- `data/violation_reference.csv`
- `data/Transformer-assist_Semantic_Cluster.csv`
- `data/parking_clean_transformer_semantic_cluster.parquet`