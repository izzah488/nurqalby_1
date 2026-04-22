"""
get_predictions.py
==================
Calls your NurQalby /recommend API for each test query
and saves results to predictions.csv.

BEFORE RUNNING:
  1. Make sure your FastAPI backend is running on Render (or locally)
  2. Update API_URL below with your actual URL
"""

import requests
import pandas as pd
import os
import time

# ── Config ───────────────────────────────────────────────────────────────────
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

API_URL    = "http://10.186.181.134:8000/recommend"
TOP_K      = 5     # how many results to retrieve per query
SLEEP_SEC  = 1.0   # delay between requests (be nice to the server)

queries_path = os.path.join(SCRIPT_DIR, "test_queries.csv")
output_path  = os.path.join(SCRIPT_DIR, "predictions.csv")

# ── Load queries ─────────────────────────────────────────────────────────────
queries = pd.read_csv(queries_path)
print(f"Loaded {len(queries)} queries")
print(f"Sending to: {API_URL}\n")

# ── Call API ─────────────────────────────────────────────────────────────────
results = []
errors  = []

for i, row in queries.iterrows():
    qid = row["query_id"]
    try:
        payload = {
            "text":    row["text"],
            "emotion": row["emotion"],
            "cause":   row["cause"],
            "top_k":   TOP_K
        }

        resp = requests.post(API_URL, json=payload, timeout=30)
        resp.raise_for_status()
        data = resp.json()

        # Handle both list and dict responses
        items = data if isinstance(data, list) else data.get("results", data.get("recommendations", []))

        for rank, item in enumerate(items[:TOP_K], start=1):
            results.append({
                "query_id": qid,
                "surah":    item.get("surah"),
                "ayah":     item.get("ayah"),
                "rank":     rank,
                "score":    item.get("score", item.get("similarity", 0))
            })

        print(f"  ✅ {qid} — got {len(items)} results")

    except Exception as e:
        errors.append(qid)
        print(f"  ❌ {qid} — ERROR: {e}")

    time.sleep(SLEEP_SEC)

# ── Save ─────────────────────────────────────────────────────────────────────
df = pd.DataFrame(results)
df.to_csv(output_path, index=False)

print()
print("=" * 45)
print(f"✅ Saved {len(df)} prediction rows → {output_path}")
if errors:
    print(f"⚠️  Failed queries: {errors}")
    print("   Re-run or check your API URL / connection.")
else:
    print("🎉 All queries successful!")
