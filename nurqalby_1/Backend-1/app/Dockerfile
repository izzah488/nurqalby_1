# ─────────────────────────────────────────────
#  NurQalby FastAPI Backend — Docker Image
#  Optimised for Google Cloud Run
# ─────────────────────────────────────────────

# Use official Python 3.11 slim image (smaller than full)
FROM python:3.11-slim

# Set working directory inside container
WORKDIR /app

# ── 1. Install system dependencies ───────────
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# ── 2. Copy requirements first (better Docker layer caching) ──
COPY requirements.txt .

# ── 3. Install Python packages ───────────────
RUN pip install --no-cache-dir -r requirements.txt

# ── 4. Pre-download ML models into the image ─
#    This happens at BUILD time so container starts fast.
#    Models are cached in /app/models/
RUN python -c "\
from sentence_transformers import SentenceTransformer; \
import os; \
os.makedirs('/app/models/sentence', exist_ok=True); \
m = SentenceTransformer('all-MiniLM-L6-v2', cache_folder='/app/models/sentence'); \
print('sentence-transformer downloaded OK')"

RUN python -c "\
from transformers import pipeline; \
import os; \
os.makedirs('/app/models/emotion', exist_ok=True); \
pipeline('text-classification', model='j-hartmann/emotion-english-distilroberta-base', \
         cache_dir='/app/models/emotion', top_k=None); \
print('emotion classifier downloaded OK')"

# ── 5. Copy application code ──────────────────
COPY main.py .
COPY dataset/ ./dataset/

# ── 6. Set environment variables ──────────────
ENV PYTHONUNBUFFERED=1
ENV HF_HOME=/app/models/emotion
ENV SENTENCE_TRANSFORMERS_HOME=/app/models/sentence
ENV PORT=8080

# ── 7. Expose port (Cloud Run uses 8080) ──────
EXPOSE 8080

# ── 8. Start the server ───────────────────────
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
