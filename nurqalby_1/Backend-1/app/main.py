from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import pandas as pd
import numpy as np
from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity

app = FastAPI(title="Quran Verse Recommender API")

# Allow Flutter to call this API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load once at startup
print("Loading model...")
model = SentenceTransformer("all-MiniLM-L6-v2")
df    = pd.read_csv("../dataset/verses.csv")
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
    # Filter by emotion + cause
    filtered = df[
        (df["emotion"].str.lower() == data.emotion.lower()) &
        (df["cause"].str.lower()   == data.cause.lower())
    ].reset_index(drop=True)

    used_filter = True
    if filtered.empty:
        filtered    = df.reset_index(drop=True)
        used_filter = False

    # Encode
    verse_texts      = filtered["verse_text"].tolist()
    verse_embeddings = model.encode(verse_texts)
    user_embedding   = model.encode([data.text])

    # Similarity
    similarities = cosine_similarity(user_embedding, verse_embeddings)[0]
    top_k        = min(data.top_k, len(filtered))
    top_indices  = np.argsort(similarities)[-top_k:][::-1]

    results = []
    for rank, idx in enumerate(top_indices, start=1):
        row = filtered.iloc[idx]
        results.append({
            "rank"       : rank,
            "surah"      : int(row["surah"]),
            "ayah"       : int(row["ayah"]),
            "verse_text" : row["verse_text"],
            "emotion"    : row["emotion"],
            "cause"      : row["cause"],
            "score"      : round(float(similarities[idx]), 4),
            "audio_url"  : generate_audio_url(row["surah"], row["ayah"])
        })

    return {
        "filter_applied" : used_filter,
        "total_results"  : len(results),
        "results"        : results
    }