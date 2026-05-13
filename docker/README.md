# Homelab Docker Stack

Self-hosted AI and development services running on macOS with Docker Compose. All services use HTTPS with internal TLS certificates via Caddy.

## Services

| Service | URL | Description | Documentation |
|---------|-----|-------------|---------------|
| **OpenWeb UI** | `https://openwebui.home.arpa` | Chat interface for Ollama and LLM providers | [📖 Guide](docs/services/openwebui.md) |
| **SearXNG** | `https://search.home.arpa` | Privacy-respecting metasearch engine | [📖 Guide](docs/services/searxng.md) |
| **Jupyter** | `https://jupyter.home.arpa` | Interactive Python notebooks and data science | [📖 Guide](docs/services/jupyter.md) |
| **Kokoro TTS** | `https://kokoro.home.arpa/web` | Fast text-to-speech with 67 voices | [📖 Guide](docs/services/kokoro-tts.md) |
| **Caddy** | Internal | Reverse proxy with automatic HTTPS | — |

## Quick Start

```bash
# 1. Configure environment variables
cp .env.example .env
# Edit .env and set secure keys (use: openssl rand -hex 32)

# 2. Set up hosts file
sudo bash scripts/setup-hosts.sh

# 3. Trust Caddy CA certificate (avoids browser warnings)
docker compose up -d caddy
sleep 5
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain \
  ./data/caddy/data/caddy/pki/authorities/local/root.crt

# 4. Start all services
docker compose up -d

# 5. Access services
open https://openwebui.home.arpa
open https://jupyter.home.arpa
open https://kokoro.home.arpa/web
```

**First-time setup?** See the [detailed setup guide](docs/setup/initial-setup.md).

## Documentation

### Setup Guides
- [Initial Setup](docs/setup/initial-setup.md) - Complete first-time configuration
- [Networking & TLS](docs/setup/networking.md) - Hosts file, Caddy, certificates

### Service Documentation
- [OpenWeb UI](docs/services/openwebui.md) - Chat interface, RAG, web search
- [Jupyter](docs/services/jupyter.md) - Notebooks, Code Interpreter integration
- [Kokoro TTS](docs/services/kokoro-tts.md) - Text-to-speech setup and voices
- [SearXNG](docs/services/searxng.md) - Search engine configuration

### Troubleshooting
- [Common Issues](docs/troubleshooting.md) - Solutions for frequent problems

## Service Management

```bash
# View all service logs
docker compose logs -f

# View specific service
docker compose logs -f openwebui

# Restart a service
docker compose restart openwebui

# Stop all services
docker compose down

# Update to latest images
docker compose pull && docker compose up -d
```

## Architecture

All services run on a `proxy` Docker network and communicate via service names. Ollama runs on the host and is accessible via `host.docker.internal:11434`.

**Data persistence**: All service data is stored in `./data/[service]/` directories.

**Auto-updates**: Watchtower checks for image updates daily at 04:00.

## Security Notes

- All services use internal TLS certificates via Caddy
- Services bind to localhost (127.0.0.1) by default
- Use `--lan` flag with setup script for network access
- Keep secrets in `.env` file (excluded from git)

## Configuration Files

- `compose.yml` - Service definitions
- `Caddyfile` - Reverse proxy and TLS configuration
- `.env` - Environment variables and secrets (not in git)
- `config/searxng/settings.yml` - SearXNG search engine settings

## Requirements

- macOS (tested on Apple Silicon)
- Docker Desktop
- Ollama running on host (for OpenWeb UI)
