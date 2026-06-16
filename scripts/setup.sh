#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# Load environment
if [ -f .env ]; then
    set -a; source .env; set +a
else
    echo "No .env found — copying from .env.example"
    cp .env.example .env
    set -a; source .env; set +a
fi

MODELS="${MODELS:-llama3.2:3b}"
COMPOSE_FILES="-f docker-compose.yml"

# Detect GPU
if command -v nvidia-smi &>/dev/null && nvidia-smi &>/dev/null; then
    echo "[✓] NVIDIA GPU detected"
else
    echo "[!] No NVIDIA GPU detected — using CPU-only mode"
    COMPOSE_FILES="$COMPOSE_FILES -f docker-compose.cpu.yml"
fi

# Create certs directory (nginx expects it even if empty)
mkdir -p nginx/certs

# Start services
echo "[*] Starting services..."
docker compose $COMPOSE_FILES up -d

# Wait for Ollama to be healthy
echo "[*] Waiting for Ollama to be ready..."
until curl -sf http://localhost:${OLLAMA_PORT:-11434}/api/tags >/dev/null 2>&1; do
    sleep 2
done
echo "[✓] Ollama is ready"

# Pull models
IFS=',' read -ra MODEL_LIST <<< "$MODELS"
for model in "${MODEL_LIST[@]}"; do
    model="$(echo "$model" | xargs)"  # trim whitespace
    echo "[*] Pulling model: $model"
    docker exec ollama ollama pull "$model"
done

echo ""
echo "============================================"
echo " Ollama is running!"
echo " Local API:    http://localhost:${OLLAMA_PORT:-11434}"
echo " Gateway:      http://localhost:${GATEWAY_PORT:-8080}"
echo "============================================"
