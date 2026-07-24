import numpy as np
import pandas as pd

from rapidfuzz.fuzz import ratio
from rapidfuzz.distance import DamerauLevenshtein
from sentence_transformers import SentenceTransformer


def prepare_underprocess_columns(df: pd.DataFrame) -> pd.DataFrame:
    # Sort and normalize the working "underprocess" columns used for clustering.
    df = df.sort_values("occurrence", ascending=True)

    if "code_underprocess" not in df.columns:
        df["code_underprocess"] = df["violation_code"]
    if "desc_underprocess" not in df.columns:
        df["desc_underprocess"] = df["violation_description"]
    if "fine_underprocess" not in df.columns:
        df["fine_underprocess"] = df["fine_amount"]

    # deleting +,-,#,.
    df["code_underprocess"] = (
        df["code_underprocess"]
        .astype("string")
        .str.replace(r"[+\.\-#]", "", regex=True)
    )

    code_fix = (df["code_underprocess"].notna() &
        (df["code_underprocess"] != df["code_underprocess"].str.strip())
    ).sum()

    desc_fix = (df["desc_underprocess"].notna() &
        (df["desc_underprocess"] != df["desc_underprocess"].str.strip())
    ).sum()

    if code_fix or desc_fix:
        df["code_underprocess"] = df["code_underprocess"].str.strip()
        df["desc_underprocess"] = df["desc_underprocess"].str.strip()

    code_lower = (df["code_underprocess"].notna() &
                  (df["code_underprocess"] != df["code_underprocess"].str.upper())
    ).sum()

    desc_lower = (df["desc_underprocess"].notna() &
                  (df["desc_underprocess"] != df["desc_underprocess"].str.upper())
    ).sum()

    if code_lower or desc_lower:
        df["code_underprocess"] = df["code_underprocess"].str.upper()
        df["desc_underprocess"] = df["desc_underprocess"].str.upper()

    return df




def assign_nearest_cluster(
    df: pd.DataFrame,
    entries_df: pd.DataFrame,
    out_csv_path: str | None = None
) -> pd.DataFrame:

    # number of entries in df
    n = len(df)

    # creating sets for assigning clustering labels
    code_set = df["code_underprocess"]
    desc_set = df["desc_underprocess"]
    fines = df["fine_underprocess"]

    # creating sentence transformer model and embeddings for description
    model = SentenceTransformer("all-MiniLM-L6-v2")
    embeddings = model.encode(desc_set.tolist(), convert_to_numpy=True, normalize_embeddings=True)


    if entries_df.empty:
        out_df = entries_df.copy()
        if out_csv_path is not None:
            out_df.to_csv(out_csv_path, index=False)
        return out_df

    entries_df = entries_df.copy()
    entries_df["cluster"] = -1

    for entry_idx, entry_row in entries_df.iterrows():
        entry_code = entry_row.get("code_underprocess")
        if pd.isna(entry_code) or str(entry_code).strip() == "":
            entry_code = entry_row.get("violation_code", "")
        entry_code = "" if pd.isna(entry_code) else str(entry_code).strip().upper()

        entry_desc = entry_row.get("desc_underprocess")
        if pd.isna(entry_desc) or str(entry_desc).strip() == "":
            entry_desc = entry_row.get("violation_description", "")
        entry_desc = "" if pd.isna(entry_desc) else str(entry_desc).strip().upper()

        entry_fine = entry_row.get("fine_underprocess")
        entry_fine_num = pd.to_numeric(entry_fine, errors="coerce")

        entry_embedding = None
        if entry_desc != "":
            entry_embedding = model.encode(
                [entry_desc],
                convert_to_numpy=True,
                normalize_embeddings=True
            )[0]

        best_i = None
        best_distance = float("inf")

        for i in range(n):
            if entry_code == "":
                code_score = 0.0
            else:
                raw_code_score = DamerauLevenshtein.normalized_similarity(
                    entry_code,
                    code_set.iloc[i]
                )
                code_score = raw_code_score ** (15 * max((1 - raw_code_score), 0))

            if entry_embedding is None:
                desc_score = 0.0
            else:
                rapid_score = ratio(entry_desc, desc_set.iloc[i]) / 100.0
                mini_score = max(float(np.dot(entry_embedding, embeddings[i])), 0)
                desc_score = (
                    1.0 if (rapid_score > 0.83) or (mini_score > 0.85)
                    else mini_score ** (8 * max((1 - mini_score), 0))
                )

            fine_score = (
                0.0
                if pd.isna(entry_fine_num) or abs(float(entry_fine_num)) <= 0.01
                else float(abs(float(entry_fine_num) - float(fines.iloc[i])) <= 0.01)
            )

            distance = (3 - (code_score + desc_score + fine_score)) / 3.0
            if distance < best_distance:
                best_distance = distance
                best_i = i

        if best_i is not None:
            entries_df.at[entry_idx, "cluster"] = int(df.loc[best_i, "cluster"])

    if out_csv_path is not None:
        entries_df.to_csv(out_csv_path, index=False)
    return entries_df
