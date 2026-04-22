"""
generate_ground_truth.py (GRADED RELEVANCE VERSION)
=====================================================
Generates a realistic ground_truth.csv using graded relevance:
  2 = Highly relevant   (strong keyword match + correct emotion + correct cause)
  1 = Moderately relevant (weaker match, same emotion/cause but more generic)
  0 = Not relevant

Logic:
- Only verses matching BOTH emotion AND cause are considered
- TF-IDF similarity ranks them against the query text
- Top 2-3 get relevance=2, next 2-3 get relevance=1, rest get 0
- Total relevant per query capped at 5-6 (realistic, not too easy)
"""

import os
import pandas as pd

# ── Paths ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR   = os.path.dirname(os.path.abspath(__file__))
verses_path  = os.path.join(SCRIPT_DIR, "verses.csv")
queries_path = os.path.join(SCRIPT_DIR, "test_queries.csv")
output_path  = os.path.join(SCRIPT_DIR, "ground_truth.csv")

# ── Load data ─────────────────────────────────────────────────────────────────
verses  = pd.read_csv(verses_path)
queries = pd.read_csv(queries_path)

print(f"Loaded {len(verses)} verses and {len(queries)} queries")

# ── Simple keyword scorer ──────────────────────────────────────────────────────
import re

def tokenize(text):
    return set(re.findall(r'\b[a-zA-Z]{3,}\b', text.lower()))

STOPWORDS = {
    'the','and','for','that','this','with','from','are','was','will','have',
    'has','had','not','but','they','their','them','who','what','when','where',
    'all','one','can','its','our','you','your','his','her','him','she','his',
    'into','upon','those','which','such','unto','said','also','been','more',
    'most','than','then','these','does','did','may','shall','just','over',
    'also','each','only','very','even','any','out','him', 'indeed','their'
}

def keyword_score(query_text, verse_text):
    q_tokens = tokenize(query_text) - STOPWORDS
    v_tokens = tokenize(verse_text) - STOPWORDS
    if not q_tokens:
        return 0
    overlap = q_tokens & v_tokens
    return len(overlap) / len(q_tokens)

# ── Build emotion-level keywords to boost specificity ────────────────────────
EMOTION_KEYWORDS = {
    'Sadness':  ['grief','sorrow','tears','lost','hopeless','mourn','cry','pain','broken','despair','weep'],
    'Fear':     ['afraid','scared','anxious','worry','danger','threat','tremble','dread','uncertainty','terror'],
    'Anger':    ['angry','rage','injustice','betrayal','frustrate','furious','wrath','resentment','unfair'],
    'Joy':      ['happy','grateful','bless','peace','thankful','rejoice','delight','glad','content','praise'],
}

CAUSE_KEYWORDS = {
    'Life Trials / Hardship':   ['hardship','trial','difficulty','struggle','test','patience','suffer','burden','relief'],
    'Faith / Spiritual State':  ['faith','prayer','worship','taqwa','sin','guidance','belief','god','allah','soul'],
    'Relationships / People':   ['family','friend','people','betrayal','trust','love','companion','bond','hurt','forgive'],
}

def relevance_score(query_row, verse_row):
    """Score 0.0–1.0 combining keyword match + emotion/cause keyword presence."""
    base   = keyword_score(query_row['text'], verse_row['verse_text'])
    emo    = query_row['emotion']
    cause  = query_row['cause']

    emo_kws   = EMOTION_KEYWORDS.get(emo, [])
    cause_kws = CAUSE_KEYWORDS.get(cause, [])

    v_lower = verse_row['verse_text'].lower()
    emo_hit   = sum(1 for k in emo_kws   if k in v_lower) / max(len(emo_kws), 1)
    cause_hit = sum(1 for k in cause_kws if k in v_lower) / max(len(cause_kws), 1)

    return base * 0.4 + emo_hit * 0.35 + cause_hit * 0.25

# ── Generate ground truth ─────────────────────────────────────────────────────
records = []

for _, q in queries.iterrows():
    qid     = q['query_id']
    emotion = q['emotion']
    cause   = q['cause']

    # Only verses matching BOTH emotion AND cause
    pool = verses[
        (verses['emotion'] == emotion) &
        (verses['cause']   == cause)
    ].copy()

    if pool.empty:
        print(f"  ⚠️  {qid}: No matching verses for {emotion} / {cause}")
        continue

    # Score each verse
    pool['score'] = pool.apply(lambda row: relevance_score(q, row), axis=1)
    pool = pool.sort_values('score', ascending=False).reset_index(drop=True)

    n = len(pool)

    # Graded relevance assignment:
    #   Top 2 → relevance 2   (highly relevant)
    #   Next 2-3 → relevance 1 (moderately relevant)
    #   Rest → relevance 0
    # Cap total relevant at 5 to avoid "too easy" ground truth

    n_high = min(2, n)                         # always exactly 2 highly relevant
    n_mid  = min(3, max(0, n - n_high))        # up to 3 moderately relevant
    n_mid  = min(n_mid, 5 - n_high)            # cap total relevant at 5

    for i, row in pool.iterrows():
        if i < n_high:
            rel = 2
        elif i < n_high + n_mid:
            rel = 1
        else:
            rel = 0

        records.append({
            'query_id':  qid,
            'surah':     row['surah'],
            'ayah':      row['ayah'],
            'relevance': rel,
            'score':     round(row['score'], 4)
        })

# ── Save ──────────────────────────────────────────────────────────────────────
df = pd.DataFrame(records)
df.to_csv(output_path, index=False)

# ── Summary ───────────────────────────────────────────────────────────────────
print()
print("=" * 50)
print(f"✅ Ground truth saved → {output_path}")
print(f"   Total rows          : {len(df)}")
print(f"   Relevance = 2 (high): {(df['relevance']==2).sum()}")
print(f"   Relevance = 1 (mid) : {(df['relevance']==1).sum()}")
print(f"   Relevance = 0 (none): {(df['relevance']==0).sum()}")
print()

# Per-query summary
print("Per-query relevant count (rel > 0):")
summary = df[df['relevance'] > 0].groupby('query_id').size()
for qid, cnt in summary.items():
    high = df[(df['query_id']==qid) & (df['relevance']==2)].shape[0]
    mid  = df[(df['query_id']==qid) & (df['relevance']==1)].shape[0]
    print(f"  {qid}: {cnt} relevant  ({high} high, {mid} mid)")
