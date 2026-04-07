from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import pandas as pd
import numpy as np
from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity
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

print("Loading model...")
model = SentenceTransformer("all-MiniLM-L6-v2")
df    = pd.read_csv(CSV_PATH)
print(f"Ready. {len(df)} verses loaded.")


class UserInput(BaseModel):
    text    : str
    emotion : str
    cause   : str
    top_k   : int = 3


def generate_audio_url(surah, ayah):
    return f"https://everyayah.com/data/Alafasy_64kbps/{str(surah).zfill(3)}{str(ayah).zfill(3)}.mp3"


@app.get("/")
def root():
    return {"status": "ok", "message": "Quran Recommender API is running"}


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
            "audio_url"   : generate_audio_url(row["surah"], row["ayah"])
        })

    return {
        "filter_applied" : used_filter,
        "total_results"  : len(results),
        "results"        : results
    }

# Load duas dataset
DUA_PATH = os.path.join(BASE_DIR, "dataset", "duas.csv")
df_dua   = pd.read_csv(DUA_PATH)

print(f"Ready. {len(df)} verses and {len(df_dua)} duas loaded.")

# Encode duas once at startup
dua_texts      = df_dua["english_text"].tolist()
dua_embeddings = model.encode(dua_texts)


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
        "results":       results
    }

if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)