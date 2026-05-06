# homelab

Infrastructure and applications for a Turing Pi 2 homelab: a Kubernetes cluster managed with Flux CD GitOps, plus local Docker services running on macOS.

## Repository structure

```
homelab/
├── kubernetes/        # Flux CD GitOps for the Turing Pi 2 cluster
│   ├── clusters/
│   └── apps/
└── docker/            # Docker Compose stack for local macOS services
    ├── compose.yml
    ├── Caddyfile
    ├── searxng/
    └── scripts/
```

---

## Kubernetes

The cluster runs on a Turing Pi 2 board and is managed by [Flux CD](https://fluxcd.io/).

Flux watches the `main` branch of this repo and reconciles the cluster state from `kubernetes/clusters/staging/`. Any change pushed to `main` is automatically applied within ~1 minute.

See [`kubernetes/`](./kubernetes/) for cluster and app manifests.

---

## Docker

A Docker Compose stack providing local AI and search services on macOS, fronted by Caddy with automatic internal TLS.

### Services

| Service    | URL                          | Description                        |
|------------|------------------------------|------------------------------------|
| Open WebUI | https://openwebui.home.arpa  | Chat UI backed by local Ollama     |
| SearXNG    | https://search.home.arpa     | Self-hosted metasearch engine      |

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) running
- [Ollama](https://ollama.com/) installed natively via Homebrew and running (`brew services start ollama`) — models are served via Metal GPU and exposed to containers at `host.docker.internal:11434`

### Quick start

```bash
cd docker/

# 1. Configure secrets
cp .env.example .env
# Edit .env — set SEARXNG_SECRET_KEY=$(openssl rand -hex 32)

# 2. Add local DNS entries
sudo bash scripts/setup-hosts.sh
# Use --lan flag to bind to your LAN IP instead of 127.0.0.1

# 3. Start the stack
docker compose up -d

# 4. Trust Caddy's local CA (required once per machine)
# caddy trust won't work inside the container — it would only update the container's
# trust store, not macOS Keychain. Import the cert directly from the bind-mount instead:
sudo security add-trusted-cert -d -r trustRoot \
  -k /Library/Keychains/System.keychain \
  data/caddy/data/caddy/pki/authorities/local/root.crt
# Caddy persists this CA across restarts, so this only needs to be done once.

# 5. Open
open https://openwebui.home.arpa
open https://search.home.arpa
```

### Persistent data

All service data is stored in `docker/data/` (bind-mounted, gitignored) on the Mac host filesystem — no data is hidden inside Docker volumes.
