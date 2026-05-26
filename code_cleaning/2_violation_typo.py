import numpy as np
import pandas as pd
import networkx as nx
from rapidfuzz.fuzz import ratio
from rapidfuzz.distance import DamerauLevenshtein
from sentence_transformers import SentenceTransformer
from itertools import combinations


df = pd.read_csv("data/violation_reference.csv")

# Sorting based on occurence
df = df.sort_values("occurrence", ascending=True)

# Checking if extra space character exist in violation_code and violation_description
code_fix = (df["code_corrected"].notna() &
    (df["code_corrected"] != df["code_corrected"].str.strip())
).sum()

desc_fix = (df["desc_corrected"].notna() &
    (df["desc_corrected"] != df["desc_corrected"].str.strip())
).sum()

# If extra space character exist, deleting them and printing sample of changes due to space deletion
if code_fix or desc_fix:

    # Deleting extra space characters
    df["code_corrected"] = df["code_corrected"].str.strip()
    df["desc_corrected"] = df["desc_corrected"].str.strip()

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
code_lower = (df["code_corrected"].notna() & 
              (df["code_corrected"] != df["code_corrected"].str.upper())
).sum()

desc_lower = (df["desc_corrected"].notna() & 
              (df["desc_corrected"] != df["desc_corrected"].str.upper())
).sum()

# If CAPITALIZATION is required, perform and print an small sample of changes due to capitilization
if code_lower or desc_lower:
    df["code_corrected"] = df["code_corrected"].str.upper()
    df["desc_corrected"] = df["desc_corrected"].str.upper()

    # printing
    sample = df.loc[
        (df["violation_code"] != df["violation_code"].str.upper()) |
        (df["violation_description"] != df["violation_description"].str.upper()),
        ["violation_code", "violation_description"]
    ].head()

    # print(f"Code uppercase corrections: {code_lower}")
    # print(f"Description uppercase corrections: {desc_lower}")
    # print(sample)


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


df = df.drop(zero_fine_entries.index)

# resetting index as drpping rows may create zero in dataframe's index
df = df.reset_index(drop=True)

df.to_csv("data/violation_reference_1.csv", index=False)

#------------

node_id_set = df["violation_reference_id"]
code_set = df["code_corrected"]
desc_set = df["desc_corrected"]
fines = df["fine_corrected"]
n = len(df)

model = SentenceTransformer("all-MiniLM-L6-v2")
embeddings = model.encode(desc_set.tolist(), convert_to_numpy=True, normalize_embeddings=True)

code_link_graph = nx.Graph()
desc_link_graph = nx.Graph()
fee_link_graph = nx.Graph()
distance_graph = nx.Graph()

for row in df.itertuples(index=False):
    node_id = row.violation_reference_id
    attrs = row._asdict()
    code_link_graph.add_node(node_id, **attrs)
    desc_link_graph.add_node(node_id, **attrs)
    fee_link_graph.add_node(node_id, **attrs)
    distance_graph.add_node(node_id, **attrs)

for i, j in combinations(range(n), 2):
    u, v = node_id_set.iloc[i], node_id_set.iloc[j]

    # code score
    code_score = DamerauLevenshtein.normalized_similarity(code_set.iloc[i], code_set.iloc[j]) ** 2.5
    
    # desc score
    rapid_score = ratio(desc_set.iloc[i], desc_set.iloc[j]) / 100.0
    mini_score = float(np.dot(embeddings[i], embeddings[j]))
    desc_score = 1.0 if (rapid_score > 0.75) or (mini_score > 0.85) else ((rapid_score + mini_score) ** 3) / 8.0
    
    # fine_score
    fine_score = 1.0 if fines.iloc[i] == fines.iloc[j] else 0.0
    
    # distance
    distance = 3 - (code_score + desc_score + fine_score)

    # adding edge in 4 different graphs
    code_link_graph.add_edge(u, v, weight=code_score)
    desc_link_graph.add_edge(u, v, weight=desc_score)
    fee_link_graph.add_edge(u, v, weight=fine_score)
    distance_graph.add_edge(u, v, weight=distance)