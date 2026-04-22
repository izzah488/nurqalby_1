from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import pandas as pd
import numpy as np
from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity
from transformers import pipeline
import os

app = FastAPI(title="Quran Verse Recommender API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Fix path — works both locally and on Render
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CSV_PATH = os.path.join(BASE_DIR, "dataset", "verses.csv")
DUA_PATH = os.path.join(BASE_DIR, "dataset", "duas.csv")

# ── Load sentence-transformer ──────────────────────────────────────────────────
print("Loading sentence transformer model...")
model = SentenceTransformer("all-MiniLM-L6-v2")

# ── Load datasets ──────────────────────────────────────────────────────────────
df     = pd.read_csv(CSV_PATH)
df_dua = pd.read_csv(DUA_PATH)
print(f"Ready. {len(df)} verses and {len(df_dua)} duas loaded.")

# ── Pre-encode duas once at startup ────────────────────────────────────────────
dua_texts      = df_dua["english_text"].tolist()
dua_embeddings = model.encode(dua_texts)

# ── Load emotion classifier ────────────────────────────────────────────────────
print("Loading emotion classifier...")
emotion_classifier = pipeline(
    "text-classification",
    model="j-hartmann/emotion-english-distilroberta-base",
    top_k=None,   # ← changed from top_k=1 to return ALL scores
)
print("Emotion classifier ready.")

# Map model labels → your 4 app emotions
EMOTION_MAP = {
    "joy":      "joy",
    "sadness":  "sadness",
    "anger":    "anger",
    "fear":     "fear",
    "disgust":  "anger",    # disgust → anger
    "surprise": "joy",      # surprise → joy
    "neutral":  "sadness",  # neutral  → sadness
}

# Your 4 target emotions
TARGET_EMOTIONS = ["anger", "fear", "joy", "sadness"]


# ── Pydantic models ────────────────────────────────────────────────────────────
class UserInput(BaseModel):
    text    : str
    emotion : str
    cause   : str
    top_k   : int = 3


class TextOnly(BaseModel):
    text: str


# ── Helpers ────────────────────────────────────────────────────────────────────
def generate_audio_url(surah, ayah):
    return (
        f"https://everyayah.com/data/Alafasy_64kbps/"
        f"{str(surah).zfill(3)}{str(ayah).zfill(3)}.mp3"
    )


# ── Routes ─────────────────────────────────────────────────────────────────────
@app.get("/")
def root():
    return {"status": "ok", "message": "Quran Recommender API is running"}


@app.post("/classify_emotion")
def classify_emotion(data: TextOnly):
    # Get ALL label scores from the model
    all_results = emotion_classifier(data.text)[0]  # list of {label, score}

    # Aggregate scores into your 4 target emotions
    aggregated = {e: 0.0 for e in TARGET_EMOTIONS}
    for item in all_results:
        raw_label = item["label"].lower()
        mapped    = EMOTION_MAP.get(raw_label)
        if mapped:
            aggregated[mapped] += item["score"]

    # Normalise so all 4 scores sum to 1.0
    total = sum(aggregated.values())
    if total > 0:
        aggregated = {k: round(v / total, 4) for k, v in aggregated.items()}

    # Detected emotion = highest aggregated score
    detected_emotion = max(aggregated, key=aggregated.get)
    confidence       = aggregated[detected_emotion]

    # Also get the raw top label for reference
    top_raw = max(all_results, key=lambda x: x["score"])

    return {
        "detected_emotion": detected_emotion,
        "confidence":       confidence,
        "raw_label":        top_raw["label"].lower(),
        "all_scores": {          # ← NEW: all 4 emotion percentages
            "anger":   aggregated["anger"],
            "fear":    aggregated["fear"],
            "joy":     aggregated["joy"],
            "sadness": aggregated["sadness"],
        },
    }


@app.post("/recommend")
def recommend(data: UserInput):
    filtered = df[
        (df["emotion"].str.lower() == data.emotion.lower()) &
        (df["cause"].str.lower()   == data.cause.lower())
    ].reset_index(drop=True)

    used_filter = True
    if filtered.empty:
        filtered    = df.reset_index(drop=True)
        used_filter = False

    verse_texts      = filtered["verse_text"].tolist()
    verse_embeddings = model.encode(verse_texts)
    user_embedding   = model.encode([data.text])

    similarities = cosine_similarity(user_embedding, verse_embeddings)[0]
    top_k        = min(data.top_k, len(filtered))
    top_indices  = np.argsort(similarities)[-top_k:][::-1]

    results = []
    for rank, idx in enumerate(top_indices, start=1):
        row = filtered.iloc[idx]
        results.append({
            "rank"        : rank,
            "surah"       : int(row["surah"]),
            "ayah"        : int(row["ayah"]),
            "arabic_text" : row["arabic_text"],
            "verse_text"  : row["verse_text"],
            "emotion"     : row["emotion"],
            "cause"       : row["cause"],
            "score"       : round(float(similarities[idx]), 4),
            "audio_url"   : generate_audio_url(row["surah"], row["ayah"]),
        })

    return {
        "filter_applied": used_filter,
        "total_results" : len(results),
        "results"       : results,
    }


@app.post("/recommend_dua")
def recommend_dua(data: UserInput):
    user_embedding = model.encode([data.text])
    similarities   = cosine_similarity(user_embedding, dua_embeddings)[0]

    top_k       = min(data.top_k, len(df_dua))
    top_indices = np.argsort(similarities)[-top_k:][::-1]

    results = []
    for rank, idx in enumerate(top_indices, start=1):
        row = df_dua.iloc[idx]
        results.append({
            "rank"        : rank,
            "title"       : row["title"],
            "arabic_text" : row["arabic_text"],
            "english_text": row["english_text"],
            "reference"   : row["reference"],
            "score"       : round(float(similarities[idx]), 4),
        })

    return {
        "total_results": len(results),
        "results"      : results,
    }


# ── Entry point (local dev only — Render uses uvicorn main:app directly) ───────
if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
