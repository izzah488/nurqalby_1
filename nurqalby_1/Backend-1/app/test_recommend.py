import pandas as pd
import numpy as np
from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity

# --- Valid options ---
EMOTIONS = ["fear", "joy", "anger", "sadness"]
CAUSES   = ["Faith / Spiritual State", "Life Trials / Hardship", "Relationships / People"]

# --- Load model ---
print("Loading model...")
model = SentenceTransformer("all-MiniLM-L6-v2")

# --- Load dataset ---
df = pd.read_csv("../dataset/verses.csv")
print(f"Loaded {len(df)} verses.\n")

# --- Encode all verses ---
verse_texts      = df["verse_text"].tolist()
verse_embeddings = model.encode(verse_texts)

# --- Audio URL helper ---
def generate_audio_url(surah, ayah):
    return f"https://everyayah.com/data/Alafasy_64kbps/{str(surah).zfill(3)}{str(ayah).zfill(3)}.mp3"

# --- Get user input ---
user_input = input("Enter your feeling: ").strip()

# --- Show emotion options ---
print("\nSelect emotion:")
for i, e in enumerate(EMOTIONS, 1):
    print(f"  {i}. {e}")
emotion_choice = int(input("Enter number: ").strip())
user_emotion   = EMOTIONS[emotion_choice - 1]

# --- Show cause options ---
print("\nSelect cause:")
for i, c in enumerate(CAUSES, 1):
    print(f"  {i}. {c}")
cause_choice = int(input("Enter number: ").strip())
user_cause   = CAUSES[cause_choice - 1]

print(f"\nSearching for: emotion={user_emotion}, cause={user_cause}\n")

# --- Filter dataset ---
filtered_df = df[
    (df["emotion"].str.lower() == user_emotion.lower()) &
    (df["cause"].str.strip().str.lower() == user_cause.strip().lower())
].reset_index(drop=True)

if filtered_df.empty:
    print("[No exact match found — using full dataset]\n")
    filtered_df = df.reset_index(drop=True)

# --- Encode filtered verses ---
filtered_texts      = filtered_df["verse_text"].tolist()
filtered_embeddings = model.encode(filtered_texts)
user_embedding      = model.encode([user_input])

# --- Cosine similarity ---
similarities = cosine_similarity(user_embedding, filtered_embeddings)[0]
top_k        = min(3, len(filtered_df))
top_indices  = np.argsort(similarities)[-top_k:][::-1]

# --- Show results ---
print(f"{'='*45}")
print("  TOP RECOMMENDED VERSES")
print(f"{'='*45}\n")

for rank, idx in enumerate(top_indices, start=1):
    row   = filtered_df.iloc[idx]
    score = similarities[idx]
    print(f"Rank {rank}")
    print(f"  Surah   : {row['surah']}")
    print(f"  Ayah    : {row['ayah']}")
    print(f"  arabic_text   : {row['arabic_text']}")
    print(f"  Verse   : {row['verse_text']}")
    print(f"  Emotion : {row['emotion']}")
    print(f"  Cause   : {row['cause']}")
    print(f"  Score   : {round(float(score), 4)}")
    print(f"  Audio   : {generate_audio_url(row['surah'], row['ayah'])}")
    print(f"  {'-'*40}")