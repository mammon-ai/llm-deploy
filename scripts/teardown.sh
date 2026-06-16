#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "[*] Stopping services..."
docker compose down

echo "[✓] Services stopped"
echo ""
echo "Note: Model data is preserved in the 'ollama_data' volume."
echo "To remove all data:  docker volume rm llm-deploy_ollama_data"
