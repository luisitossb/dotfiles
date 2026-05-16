# Server

Self-hosted services. Only run this on the machine that will act as a server/host.

## Usage

```bash
bash scripts/server/install.sh
```

## What gets installed

| Service | Description | Access |
|---------|-------------|--------|
| Jellyfin | Media server (movies, shows, music) | http://localhost:8096 |
| Sunshine | Game stream host — pair with Moonlight | https://localhost:47990 |
| Docker + Compose | Container runtime (used for SearXNG etc.) | — |

## After install

**Jellyfin:** Open http://localhost:8096 and set up your media libraries manually. Point it at your external drive mount path.

**Sunshine:** Open https://localhost:47990, create credentials, then on the client device open Moonlight → Add PC → enter the Tailscale IP of this machine (`tailscale ip`).

**SearXNG (optional):**
```bash
docker run -d --name searxng -p 8888:8080 --restart unless-stopped searxng/searxng:latest
```
Access at http://localhost:8888.
