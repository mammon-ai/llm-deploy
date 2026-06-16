# llm-deploy

Template for deploying [Ollama](https://ollama.com) LLM containers with a reverse-proxy gateway for remote API access.

## What you get

- **Ollama** container with GPU passthrough (auto-falls back to CPU)
- **Nginx gateway** with rate limiting, CORS, optional API key auth, and TLS support
- One-command setup that pulls your chosen models on first run

## Quick start

```bash
# 1. Clone (or use as template)
gh repo create my-llm --template mammon-ai/llm-deploy --clone
cd my-llm

# 2. Configure
cp .env.example .env
# Edit .env — set MODELS, ports, API_KEY, etc.

# 3. Launch
chmod +x scripts/*.sh
./scripts/setup.sh
```

The gateway is now reachable at `http://<host>:8080`.

## Remote endpoint usage

Once running, any machine on the network can use the Ollama API through the gateway:

```bash
# Generate
curl http://<host>:8080/api/generate -d '{
  "model": "llama3.2:3b",
  "prompt": "Hello, world!"
}'

# Chat
curl http://<host>:8080/api/chat -d '{
  "model": "llama3.2:3b",
  "messages": [{"role": "user", "content": "Explain Docker in one sentence."}]
}'

# List models
curl http://<host>:8080/api/tags
```

### Use as an OpenAI-compatible endpoint

Ollama exposes an OpenAI-compatible API at `/v1`:

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://<host>:8080/v1",
    api_key="unused",  # or your API_KEY if auth is enabled
)

response = client.chat.completions.create(
    model="llama3.2:3b",
    messages=[{"role": "user", "content": "Hello!"}],
)
```

## Configuration

| Variable | Default | Description |
|---|---|---|
| `OLLAMA_PORT` | `11434` | Direct Ollama API port |
| `GATEWAY_PORT` | `8080` | Nginx gateway HTTP port |
| `GATEWAY_TLS_PORT` | `8443` | Nginx gateway HTTPS port |
| `MODELS` | `llama3.2:3b` | Comma-separated models to pull on setup |
| `OLLAMA_NUM_PARALLEL` | `4` | Max concurrent requests per model |
| `OLLAMA_MAX_LOADED_MODELS` | `2` | Max models loaded in VRAM simultaneously |
| `API_KEY` | *(unset)* | Set + uncomment nginx auth block to enable |

## TLS

Place your certificate files in `nginx/certs/`:

```
nginx/certs/fullchain.pem
nginx/certs/privkey.pem
```

Then uncomment the TLS server block in `nginx/nginx.conf`.

## CPU-only mode

The setup script auto-detects GPU availability. To force CPU mode:

```bash
docker compose -f docker-compose.yml -f docker-compose.cpu.yml up -d
```

## Teardown

```bash
./scripts/teardown.sh
# To also remove model data:
docker volume rm llm-deploy_ollama_data
```

## License

MIT
