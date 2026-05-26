### Violation Code, Description, and Fine

[vilation code 0 will not be corrected, thus this its violation reference is set to to -999 as re]
[8069 and 8-69B same]

This stage of the cleaning pipeline focuses on the following variables:

```text
violation_code, violation_description, fine_amount
```

The cleaning methodology is based on the empirical observation that violation codes in Los Angeles parking citation data behave approximately as a functional dependency:


```text
                 1-to-1
violation_code <----------> violation_description

                many-to-1
violation_code -----------> canonical_fine

```

This means that a single violation code is expected to correspond to one well-defined violation description and one dominant fine amount. However, the reverse relationship does not hold. Multiple violation codes may legitimately share the same fine amount.

The assumption regarding fine stability is supported by both exploratory analysis and publicly available parking citation references. Los Angeles parking citation base fines appear to have remained largely stable throughout approximately 2014–2025. Publicly referenced fine amounts for common violations — including street sweeping, meter violations, driveway blocking, and red curb violations — closely match the dominant fine amounts observed in the dataset. Recent city documents discussing proposed parking fine increases in 2025–2026 also imply that many existing base fines had not substantially changed beforehand.

The cleaning logic also relies on a probabilistic assumption regarding data-entry errors. Random typographical errors are expected to occur infrequently and inconsistently. Therefore, repeated occurrences of the exact same combination are treated as strong evidence that the row is valid. High-frequency combinations are considered substantially more trustworthy than sparse low-frequency anomalies unless a systematic cause of corruption can be identified.

For example:

| violation_code | violation_description | fine_amount | count |
|---|---|---|---|
| 80.56E4+ | RED ZONE | 93 | 2,000,000 |
| 80.56E4+ | RED ZNOE | 93 | 3 |
| 80.56E4+ | RED ZONE | 39 | 1 |

In this case, the dominant row is treated as the canonical representation, while the low-frequency variants are interpreted as probable data-entry errors.

The cleaning system is designed around two separate tables: 
```text
the main citation table and a canonical correction table.
```

 The raw table stores the exact observed values from the source data and acts as an immutable historical reference. Raw values are never overwritten or deleted. This preserves auditability, provenance, reproducibility, and rollback capability. The canonical correction table stores the cleaned interpretation of the raw combinations, including corrected violation codes, descriptions, fine amounts, correction types, confidence scores, and correction reasons.

The raw  table is the raw table along with a surrogate key (`combo_id`). The canonical correction table uses the same surrogate key to map raw combinations to their cleaned canonical representation, which is obtained by collapsing the large raw table. This architecture ensures that the main citation table can always retain the original raw values while simultaneously supporting corrected analytical fields.

The correction workflow for the initial full cleaning process is:

- Collapse the main citation table into a smaller table containing unique combinations of violation code, violation description, and fine amount, along with occurrence counts and surrogate keys to connect the collapsed table to the original one.
- Create canonical correction columns for standardized values, correction types. For upcoming steps categorize entries into quartiles based on occurence.
- Perform typo correction on violation codes and violation descriptions using string similarity methods combined with supporting evidence such as matching fine amounts, similar descriptions, and relative frequency differences. While correcting higher quartile will be given preference in comparison.
- Apply majority-based correction logic. If a low-frequency row shares the same violation code and description as a dominant high-frequency row but contains a different fine amount, the low-frequency fine is treated as erroneous and replaced with the dominant canonical fine. But, when one of them agrees, then check if the fine is agrees too, then correct the disagreeing column in the lower occurence one. When in the low_occur section, first comparison will be done with the high_occur then with mid_occur.
- Validate canonical mappings using publicly available parking citation schedules, municipal regulations, and external reference documents whenever possible.
- Correct the main citation table using surrogate-key mappings from the canonical correction table while preserving the original raw values.

The ingestion workflow for newly arriving citation data is:

- Compare newly ingested records against the existing raw combination table.
- Reuse existing surrogate keys (`combo_id`) for already known raw combinations and update occurrence counts accordingly.
- Collapse previously unseen combinations into a temporary combination table containing new surrogate keys and correction metadata columns.
- Perform typo correction by comparing the temporary combinations against the previously validated canonical correction table rather than only within the temporary batch itself.
- Apply the same majority-based correction logic used during the initial cleaning stage.
- Append the newly validated combinations to the master raw combination table and canonical correction table.
- Correct the newly ingested citation records using the updated canonical mappings.

This design creates a lightweight master-data-management style cleaning system that supports incremental ingestion, probabilistic correction, auditability, reproducibility, and long-term canonical consistency while preserving the original raw citation data.
