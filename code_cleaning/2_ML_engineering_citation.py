import numpy as np
import pandas as pd
from rapidfuzz.fuzz import ratio
from rapidfuzz.distance import DamerauLevenshtein
from sentence_transformers import SentenceTransformer
from itertools import combinations
from sklearn.cluster import DBSCAN

from cleaning_utils import assign_nearest_cluster, prepare_underprocess_columns



df = pd.read_csv("data/violation_reference.csv")

# preparing columns for clustering/ comparing
df = prepare_underprocess_columns(df)


# ------------------------------
# Filtering out blank entries, zero fine entries and low frequency entries for separate handling 
#    after clustering the main dataframe.
# -----------------------------

blank_entries = df[
    df["code_underprocess"].isna() |
    (df["code_underprocess"].str.strip() == "") |
    df["desc_underprocess"].isna() |
    (df["desc_underprocess"].str.strip() == "") |
    df["fine_underprocess"].isna()
].copy()
df = df.drop(blank_entries.index)

zero_fine_entries = df[df["fine_underprocess"] == 0.0].copy()
df = df.drop(zero_fine_entries.index)

# low_freq_threshold is 400      
low_freq_entries = df[df["occurrence"] < 400].copy()
df = df.drop(low_freq_entries.index)

# Reset index before clustering (dropping rows creates gaps).
df = df.reset_index(drop=True)

# saving the main dataframe to csv for inspection
df.to_csv("data/violation_reference_1.csv", index=False)
n = len(df)


#-----------------------------
# Clustering using DBSCAN
#-----------------------------

# creating sets for DBSCAN
code_set = df["code_underprocess"]
desc_set = df["desc_underprocess"]
fines = df["fine_underprocess"]

# creating sentence transformer model and embeddings for description
model = SentenceTransformer("all-MiniLM-L6-v2")
embeddings = model.encode(desc_set.tolist(), convert_to_numpy=True, normalize_embeddings=True)

# ------------------------------
# Calculating and creating distance_matrix 
# ------------------------------

distance_matrix = np.zeros((n, n), dtype=np.float32)

for i, j in combinations(range(n), 2):

    raw_code_score = DamerauLevenshtein.normalized_similarity(
        code_set.iloc[i],
        code_set.iloc[j]
    )

    # pushing larger value closer to 1, while lower value to 0
    code_score = raw_code_score ** ( 15* max((1-raw_code_score),0 ))


    rapid_score = ratio(desc_set.iloc[i], desc_set.iloc[j]) / 100.0
    mini_score = max(float(np.dot(embeddings[i], embeddings[j])),0)  # sometime minilm can give negative number
    avg_desc_score = (rapid_score + mini_score)/2
    desc_score = (
        1.0 if (rapid_score > 0.83) or (mini_score > 0.85)
        else mini_score ** ( 8* max((1-mini_score),0))    # pushing larger value closer to 1, while lower value to 0
    )

    fine_score = float(abs(fines.iloc[i] - fines.iloc[j]) <= 0.01)

    distance = 3 - (code_score + desc_score + fine_score)

    distance_matrix[i, j] = distance / 3.0
    distance_matrix[j, i] = distance / 3.0


    '''
    #INSPECTION within the loop
    #print(f"i,j: {i,j}, distance {distance}, distance_matrix[i, j] {distance_matrix[i, j]}")
    #print(f"code_score ,desc_score , fine_score:{code_score , desc_score , fine_score}")
    
    pair_ids = {df.loc[i, "violation_reference_id"], df.loc[j, "violation_reference_id"]}
    if pair_ids == {id1, id2}:

        print(f"Matched pair at i={i}, j={j}")
        print(f"ref ids: {df.loc[i, 'violation_reference_id']}, {df.loc[j, 'violation_reference_id']}")

        print(f"code 1: {code_set.iloc[i]}")
        print(f"code 2: {code_set.iloc[j]}")
        print(f"raw_code_score: {raw_code_score}")
        print(f"code_score: {code_score}")

        print(f"mini_score, rapid_score, desc score: {mini_score, rapid_score, desc_score}")
        
        print(f"fines: {fines.iloc[i]}, {fines.iloc[j]}")
        print(f"fine_score: {fine_score}")
        print(f"distance raw: {distance}")
        print(f"distance normalized: {distance / 3.0}")
        print(f"matrix value now: {distance_matrix[i, j]}")   
    '''

# diagonal must be zero
np.fill_diagonal(distance_matrix, 0.0)

# INSPECTION of distance matrix for specific pair of reference ids (uncomment above print statements to see the details). 
#if (index1 is not None) and (index2 is not None):
#    print(f"printing form Distance matrix: {distance_matrix[index1, index2]}")

# ----------------------------
# DBSCAN
# ----------------------------
db_clustering = DBSCAN(
    eps=0.34,              # tune this
    min_samples=2,
    metric="precomputed"
)

df["cluster"] = db_clustering.fit_predict(distance_matrix)

noise_mask = df["cluster"] == -1
if noise_mask.any():
    max_cluster = df.loc[~noise_mask, "cluster"].max()
    next_cluster = 0 if pd.isna(max_cluster) else int(max_cluster) + 1
    df.loc[noise_mask, "cluster"] = np.arange(
        next_cluster,
        next_cluster + noise_mask.sum()
    )

# Assign nearest clusters for excluded rows, append them back to df, and save one combined CSV.
blank_entries = assign_nearest_cluster(df, blank_entries)
low_freq_entries = assign_nearest_cluster(df, low_freq_entries)
zero_fine_entries = assign_nearest_cluster(df, zero_fine_entries)

df = pd.concat([df, blank_entries, low_freq_entries, zero_fine_entries], ignore_index=True)

# Canonicalize underprocess fields within each cluster using non-blank highest-occurrence representatives.
top_idx = df.groupby("cluster")["occurrence"].idxmax()
top_code_map = df.loc[top_idx].set_index("cluster")["violation_code"]
top_desc_map = df.loc[top_idx].set_index("cluster")["violation_description"]
top_fine_map = df.loc[top_idx].set_index("cluster")["fine_amount"]

code_nonblank = df["violation_code"].notna() & (df["violation_code"].astype("string").str.strip() != "")
desc_nonblank = df["violation_description"].notna() & (df["violation_description"].astype("string").str.strip() != "")
fine_nonblank = pd.to_numeric(df["fine_amount"], errors="coerce").notna()

code_idx = df[code_nonblank].groupby("cluster")["occurrence"].idxmax()
desc_idx = df[desc_nonblank].groupby("cluster")["occurrence"].idxmax()
fine_idx = df[fine_nonblank].groupby("cluster")["occurrence"].idxmax()

code_map = df.loc[code_idx].set_index("cluster")["violation_code"]
desc_map = df.loc[desc_idx].set_index("cluster")["violation_description"]
fine_map = df.loc[fine_idx].set_index("cluster")["fine_amount"]

df["code_underprocess"] = df["cluster"].map(code_map).fillna(df["cluster"].map(top_code_map))
df["desc_underprocess"] = df["cluster"].map(desc_map).fillna(df["cluster"].map(top_desc_map))

# Keep the earlier rule for fine (<100 gets substituted), but always fill blank fine when possible.
rep_fine_for_cluster = df["cluster"].map(fine_map).fillna(df["cluster"].map(top_fine_map))
fine_blank_now = pd.to_numeric(df["fine_underprocess"], errors="coerce").isna()
df.loc[df["occurrence"] < 100, "fine_underprocess"] = rep_fine_for_cluster[df["occurrence"] < 100]
df.loc[(df["occurrence"] >= 100) & fine_blank_now, "fine_underprocess"] = rep_fine_for_cluster[
    (df["occurrence"] >= 100) & fine_blank_now
]


# Sanity check: ensure no blanks remain in underprocess columns after canonicalization.
code_blank = df["code_underprocess"].isna() | (df["code_underprocess"].astype("string").str.strip() == "")
desc_blank = df["desc_underprocess"].isna() | (df["desc_underprocess"].astype("string").str.strip() == "")
fine_blank = df["fine_underprocess"].isna()

if code_blank.any() or desc_blank.any() or fine_blank.any():
    print("WARNING: blanks still exist in underprocess columns:")
    print(f"  code_underprocess blanks: {int(code_blank.sum())}")
    print(f"  desc_underprocess blanks: {int(desc_blank.sum())}")
    print(f"  fine_underprocess blanks: {int(fine_blank.sum())}")
    print(
        df.loc[code_blank | desc_blank | fine_blank, [
            "violation_reference_id",
            "violation_code",
            "violation_description",
            "fine_amount",
            "occurrence",
            "cluster",
            "code_underprocess",
            "desc_underprocess",
            "fine_underprocess",
        ]].head(20).to_string(index=False)
    )
else:
    print("Sanity check passed: no blanks in underprocess columns.")

# Rename underprocess columns back to corrected names for output compatibility.
df = df.rename(columns={
    "code_underprocess": "code_corrected",
    "desc_underprocess": "desc_corrected",
    "fine_underprocess": "fine_corrected",
})

df.to_csv("data/Transformer-assist_Semantic_Cluster.csv", index=False)
