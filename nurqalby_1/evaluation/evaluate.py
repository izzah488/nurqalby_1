"""
evaluate.py (GRADED RELEVANCE VERSION)
=======================================
Calculates Precision@K, Recall@K, and nDCG@K
using graded relevance (0, 1, 2) from ground_truth.csv.

Graded nDCG formula:
  DCG  = sum( (2^rel - 1) / log2(rank + 1) )
  IDCG = DCG of ideal (perfect) ranking
  nDCG = DCG / IDCG

Precision@K: proportion of top-K results that are relevant (rel >= 1)
Recall@K:    proportion of ALL relevant items found in top K
"""

import os
import pandas as pd
import numpy as np

# ── Paths ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR        = os.path.dirname(os.path.abspath(__file__))
predictions_path  = os.path.join(SCRIPT_DIR, "predictions.csv")
ground_truth_path = os.path.join(SCRIPT_DIR, "ground_truth.csv")
output_path       = os.path.join(SCRIPT_DIR, "summary_results.csv")

# ── Load ──────────────────────────────────────────────────────────────────────
predictions  = pd.read_csv(predictions_path)
ground_truth = pd.read_csv(ground_truth_path)

print(f"Predictions : {len(predictions)} rows")
print(f"Ground truth: {len(ground_truth)} rows")

# ── Metric functions ──────────────────────────────────────────────────────────

def precision_at_k(pred_list, gt_dict, k):
    """Proportion of top-K predictions that are relevant (rel >= 1)."""
    top_k = pred_list[:k]
    hits  = sum(1 for v in top_k if gt_dict.get(v, 0) >= 1)
    return hits / k

def recall_at_k(pred_list, gt_dict, k):
    """Proportion of all relevant items found in top K."""
    top_k    = pred_list[:k]
    relevant = [v for v, r in gt_dict.items() if r >= 1]
    if not relevant:
        return 0.0
    hits = sum(1 for v in top_k if gt_dict.get(v, 0) >= 1)
    return hits / len(relevant)

def dcg_at_k(ranked_rels, k):
    """Discounted Cumulative Gain using graded relevance: (2^rel-1)/log2(rank+1)."""
    score = 0.0
    for i, rel in enumerate(ranked_rels[:k]):
        score += (2 ** rel - 1) / np.log2(i + 2)  # i+2 because log2(rank+1), rank starts at 1
    return score

def ndcg_at_k(pred_list, gt_dict, k):
    """nDCG@K with graded relevance."""
    # Get relevance of each prediction in order
    pred_rels = [gt_dict.get(v, 0) for v in pred_list[:k]]
    dcg       = dcg_at_k(pred_rels, k)

    # Ideal: sort all known relevance scores descending
    ideal_rels = sorted(gt_dict.values(), reverse=True)
    idcg       = dcg_at_k(ideal_rels, k)

    return dcg / idcg if idcg > 0 else 0.0

# ── Evaluate ──────────────────────────────────────────────────────────────────
K_VALUES    = [1, 3, 5]
query_ids   = predictions["query_id"].unique()

results_by_k = {k: {"precision": [], "recall": [], "ndcg": []} for k in K_VALUES}
per_query_rows = []

for qid in query_ids:
    # Predictions sorted by rank
    preds = predictions[predictions["query_id"] == qid].sort_values("rank")
    pred_list = list(zip(preds["surah"].astype(int), preds["ayah"].astype(int)))

    # Ground truth dict: (surah, ayah) → relevance score
    gt_rows = ground_truth[ground_truth["query_id"] == qid]
    gt_dict = {
        (int(row["surah"]), int(row["ayah"])): int(row["relevance"])
        for _, row in gt_rows.iterrows()
    }

    if not gt_dict or not any(r >= 1 for r in gt_dict.values()):
        print(f"  ⚠️  {qid}: No relevant items in ground truth — skipping")
        continue

    for k in K_VALUES:
        p    = precision_at_k(pred_list, gt_dict, k)
        r    = recall_at_k(pred_list, gt_dict, k)
        ndcg = ndcg_at_k(pred_list, gt_dict, k)
        results_by_k[k]["precision"].append(p)
        results_by_k[k]["recall"].append(r)
        results_by_k[k]["ndcg"].append(ndcg)

        per_query_rows.append({
            "query_id": qid, "k": k,
            "precision": round(p, 4),
            "recall":    round(r, 4),
            "ndcg":      round(ndcg, 4)
        })

# ── Print results ─────────────────────────────────────────────────────────────
print()
print("=" * 55)
print("  EVALUATION RESULTS — NurQalby Recommendation System")
print("=" * 55)
print(f"  Queries evaluated: {len(query_ids)}")
print(f"  Relevance scoring: Graded (2=high, 1=moderate, 0=none)")
print("=" * 55)
print(f"  {'K':<6} {'Precision@K':<16} {'Recall@K':<14} {'nDCG@K'}")
print("  " + "-" * 50)

summary_rows = []
for k in K_VALUES:
    p    = np.mean(results_by_k[k]["precision"])
    r    = np.mean(results_by_k[k]["recall"])
    n    = np.mean(results_by_k[k]["ndcg"])
    print(f"  {k:<6} {p:<16.4f} {r:<14.4f} {n:.4f}")
    summary_rows.append({"K": k, "Precision@K": round(p,4), "Recall@K": round(r,4), "nDCG@K": round(n,4)})

print("=" * 55)

# ── Save ──────────────────────────────────────────────────────────────────────
pd.DataFrame(summary_rows).to_csv(output_path, index=False)
pd.DataFrame(per_query_rows).to_csv(
    os.path.join(SCRIPT_DIR, "per_query_results.csv"), index=False
)

print(f"\n✅ summary_results.csv    → overall averages")
print(f"✅ per_query_results.csv  → breakdown per query")
print()

# ── Interpretation ────────────────────────────────────────────────────────────
avg_ndcg = np.mean(results_by_k[5]["ndcg"])
avg_prec = np.mean(results_by_k[5]["precision"])

print("📊 Result Interpretation:")
if avg_ndcg >= 0.85:
    print("   nDCG@5: Excellent — system ranks highly relevant verses at top ✅")
elif avg_ndcg >= 0.65:
    print("   nDCG@5: Good — system mostly ranks correctly ✅")
else:
    print("   nDCG@5: Moderate — ranking could be improved")

if avg_prec >= 0.7:
    print("   Precision@5: Strong — most returned verses are relevant ✅")
elif avg_prec >= 0.5:
    print("   Precision@5: Acceptable — over half returned verses are relevant ✅")
else:
    print("   Precision@5: Needs improvement — many irrelevant verses returned")
