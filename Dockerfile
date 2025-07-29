# -------- 1️⃣ Build stage: install deps in a slim image --------
FROM python:3.12-slim AS builder

# Prevents Python from writing .pyc files + ensures stdout/stderr go straight to the terminal
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Install build tools only needed for compiling wheels
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Only copy requirements first for better layer‑caching
COPY requirements.txt ./
RUN pip install --upgrade pip \
 && pip wheel --wheel-dir /wheels -r requirements.txt

# -------- 2️⃣ Runtime stage: minimal image with just the wheels --------
FROM python:3.12-slim

# Add non‑root user
ENV USER=appuser
RUN useradd --create-home --shell /bin/bash $USER
WORKDIR /home/$USER

# Copy wheels and install them
COPY --from=builder /wheels /wheels
RUN pip install --no-cache-dir --no-index --find-links /wheels /wheels/* \
 && rm -rf /wheels

# Copy application source
COPY --chown=$USER:$USER . .

# Switch to non‑root user
USER $USER

# ─── Adjust these two lines for your app ───────────────────────
EXPOSE 8000
CMD [ "python", "-m", "app.main" ]   # e.g. `python -m app.main` starts your program
