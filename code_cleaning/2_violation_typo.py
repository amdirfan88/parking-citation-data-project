import numpy as np
import pandas as pd
from rapidfuzz.fuzz import ratio
from rapidfuzz.distance import DamerauLevenshtein
from sentence_transformers import SentenceTransformer


df = pd.read_csv("data/violation_reference.csv")

# Sorting based on occurence
df = df.sort_values("occurrence", ascending=True)

# Checking if extra space character exist in violation_code and violation_description
code_fix = (
    df["violation_code"].notna() &
    (df["violation_code"] != df["violation_code"].str.strip())
).sum()

desc_fix = (
    df["violation_description"].notna() &
    (df["violation_description"] != df["violation_description"].str.strip())
).sum()

# If extra space character exist, deleting them and printing sample of changes due to space deletion
if code_fix or desc_fix:

    # Deleting extra space characters
    df["code_corrected"] = df["violation_code"].str.strip()
    df["desc_corrected"] = df["violation_description"].str.strip()

    # printing
    sample = df.loc[
        (df["violation_code"] != df["violation_code"].str.strip()) |
        (df["violation_description"] != df["violation_description"].str.strip()),
        ["violation_code", "violation_description"]
    ].head()

    # print(f"Code corrections: {code_fix}")
    # print(f"Description corrections: {desc_fix}")
    # print(sample)

# Checking if CAPITALIZATION is required in any violation_code and violation_description
code_lower = df["violation_code"].notna() & (df["violation_code"] != df["violation_code"].str.upper())
desc_lower = df["violation_description"].notna() & (df["violation_description"] != df["violation_description"].str.upper())

# If CAPITALIZATION is required, perform and print an small sample of changes due to capitilization
if code_lower.sum() or desc_lower.sum():
    df["code_corrected"] = df["violation_code"].str.upper()
    df["desc_corrected"] = df["violation_description"].str.upper()

    # print(f"Code uppercase corrections: {code_lower.sum()}")
    # print(f"Description uppercase corrections: {desc_lower.sum()}")

    # print(df.loc[code_lower | desc_lower,
    #     ["violation_code", "violation_description"]].head())


# creating different df for rows with blank/null values in corrected columns
blank_entries = df[
    df["code_corrected"].isna() |
    (df["code_corrected"].str.strip() == "") |
    df["desc_corrected"].isna() |
    (df["desc_corrected"].str.strip() == "") |
    df["fine_corrected"].isna()
].copy()

df = df.drop(blank_entries.index)


# creating different df for rows where fine_corrected = 0.0
zero_fine_entries = df[df["fine_corrected"] == 0.0].copy()

df = df[df["fine_corrected"] != 0.0]

df.to_csv("data/violation_reference_1.csv", index=False)

#------------

# pick a target to compare with other entries of the table
target = df.iloc[-1]

# printing target
print(
    f"\n-------------------------"
    f"\nTARGET ENTRY | \n"
    f"code={target['violation_code']} | "
    f"desc={target['violation_description']} | "
    f"fine={target['fine_amount']} | "
    f"occurrence={target['occurrence']}"
    f"\n-------------------------"
)


# target values
t_code = str(target["code_corrected"])
t_desc = str(target["desc_corrected"])
t_fine = target["fine_corrected"]

codes = df["code_corrected"].astype(str).to_numpy()
descs = df["desc_corrected"].astype(str).to_numpy()
fines = df["fine_corrected"].to_numpy()

# code score in 0-1
code_score = np.fromiter(
    (DamerauLevenshtein.normalized_similarity(t_code, c) ** 2.5 for c in codes),
    dtype=float,
    count=len(codes)
)

# description score in 0-1
rapid_score = np.fromiter(
    (ratio(t_desc, d) / 100.0 for d in descs),
    dtype=float,
    count=len(descs)
)

model = SentenceTransformer("all-MiniLM-L6-v2")

emb_t = model.encode([t_desc], convert_to_numpy=True, normalize_embeddings=True)[0]
emb_b = model.encode(descs.tolist(), convert_to_numpy=True, normalize_embeddings=True)

mini_score = emb_b @ emb_t  # cosine similarity in 0-1 because embeddings are normalized

desc_score = np.where(
    (rapid_score > 0.75) | (mini_score > 0.85),
    1.0,
    ((rapid_score + mini_score) ** 3) / 8.0
)

# fine score in 0-1
fine_score = np.where(fines == t_fine, 1.0, 0.0)

# save results to data/scored_results.csv
result_df = pd.DataFrame({
    "code_corrected": df["code_corrected"],
    "desc_corrected": df["desc_corrected"],
    "fine_corrected": df["fine_corrected"],
    "code_score": code_score,
    "desc_score": desc_score,
    "fine_score": fine_score,
    "total_score": code_score+desc_score+fine_score,
    "occurrence": df["occurrence"]
})

result_df.to_csv("data/scored_results.csv", index=False)