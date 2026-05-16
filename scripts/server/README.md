# Server

Self-hosted services. Only run this on the machine that will act as a server/host.

## Scripts

| Script | What it does |
|--------|-------------|
| `install.sh` | Jellyfin, Sunshine, Docker |
| `install-ai.sh` | Ollama + Open WebUI (local LLM stack) |

## Usage

```bash
bash scripts/server/install.sh       # media + streaming
bash scripts/server/install-ai.sh    # local AI stack (optional)
```

---

## install.sh

### What gets installed

| Service | Description | Access |
|---------|-------------|--------|
| Jellyfin | Media server (movies, shows, music) | http://localhost:8096 |
| Sunshine | Game stream host — pair with Moonlight | https://localhost:47990 |
| Docker + Compose | Container runtime (used for SearXNG etc.) | — |

### After install

**Jellyfin:** Open http://localhost:8096 and set up your media libraries manually. Point it at your external drive mount path.

**Sunshine:** Open https://localhost:47990, create credentials, then on the client device open Moonlight → Add PC → enter the Tailscale IP of this machine (`tailscale ip`).

**SearXNG (optional):**
```bash
docker run -d --name searxng -p 8888:8080 --restart unless-stopped searxng/searxng:latest
```
Access at http://localhost:8888.

---

## install-ai.sh

### What gets installed

| Component | Description | Access |
|-----------|-------------|--------|
| Ollama | Local LLM runtime — auto-picks CUDA/ROCm/CPU based on GPU | http://localhost:11434 |
| Open WebUI | Web frontend for Ollama — chat, RAG, web search | http://localhost:8080 |

Ollama is tuned on install: max 1 model loaded at a time, 5s VRAM keep-alive, 1 parallel request.

### After install

Pull whichever models you want:
```bash
ollama pull llama3.1:8b        # general purpose (~5GB VRAM)
ollama pull qwen2.5-coder:7b   # coding (~4.5GB VRAM)
ollama list                    # see what's installed
```

`nomic-embed-text` is pulled automatically — it's the embedding model Open WebUI uses for RAG.

**SearXNG web search** is pre-configured in Open WebUI. If you want it working, also run:
```bash
docker run -d --name searxng -p 8888:8080 --restart unless-stopped searxng/searxng:latest
```
