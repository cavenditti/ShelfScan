# ── Stage 1: Build Expo web app ──────────────────────────
FROM node:22-alpine AS frontend

WORKDIR /build/app
COPY app/package.json app/package-lock.json* ./
RUN npm ci --ignore-scripts
COPY app/ ./
RUN npx expo export --platform web

# ── Stage 2: Python backend + everything served together ─
FROM python:3.12-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# System deps (none needed for SQLite/aiosqlite, but keep layer for future)
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
    && rm -rf /var/lib/apt/lists/*

# Install backend
COPY backend/pyproject.toml backend/README.md ./
RUN pip install --no-cache-dir .

COPY backend/ ./

# Copy compiled scanner app into static dir
COPY --from=frontend /build/app/dist/ ./invenioscan/static/scan-app/

# Pre-create directories that need to be writable
RUN mkdir -p /data/uploads

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8000

ENTRYPOINT ["/entrypoint.sh"]
