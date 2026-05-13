# Initial Setup Guide

Complete first-time setup for the homelab Docker stack.

## Prerequisites

- **macOS**: Tested on Apple Silicon (M1/M2/M3)
- **Docker Desktop**: Latest version installed and running
- **Ollama or oMLX**: For LLM inference with OpenWebUI
- **Terminal Access**: For running setup commands

## Step-by-Step Setup

### 1. Clone or Download

If you haven't already, get the project files:

```bash
cd ~/Applications/homelab/docker
```

### 2. Configure Environment Variables

Environment variables store secrets and configuration that shouldn't be in git.

```bash
# Copy the example file
cp .env.example .env

# Edit the file
nano .env  # or use your preferred editor
```

**Required Variables**:

```bash
# Generate secure random keys
openssl rand -hex 32  # Run this 3 times for each key below

# Paste generated keys:
WEBUI_SECRET_KEY=your-first-random-key-here
SEARXNG_SECRET_KEY=your-second-random-key-here
JUPYTER_TOKEN=your-third-random-key-here
```

**What These Are**:
- `WEBUI_SECRET_KEY` - OpenWebUI session encryption
- `SEARXNG_SECRET_KEY` - SearXNG instance secret
- `JUPYTER_TOKEN` - Jupyter authentication token

**Save the file** and keep `.env` secure (it's in `.gitignore`).

### 3. Configure Hosts File

The setup script adds local domain names to `/etc/hosts`:

```bash
# Basic setup (localhost only)
sudo bash scripts/setup-hosts.sh

# Or for LAN access (accessible from other devices)
sudo bash scripts/setup-hosts.sh --lan
```

**What This Does**:
- Adds entries between `# homelab-start` and `# homelab-end` markers
- Maps service names to IP address (127.0.0.1 or your LAN IP)
- Allows you to use `https://openwebui.home.arpa` instead of `https://localhost`

**Registered Hostnames**:
- `openwebui.home.arpa` / `openwebui`
- `search.home.arpa` / `search`
- `jupyter.home.arpa` / `jupyter`
- `kokoro.home.arpa` / `kokoro`
- `omlx.home.arpa` / `omlx`

### 4. Trust Caddy CA Certificate

To avoid browser security warnings for internal TLS certificates:

```bash
# Start Caddy to generate certificates
docker compose up -d caddy

# Wait for CA generation
sleep 5

# Trust the Caddy CA certificate
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain \
  ./data/caddy/data/caddy/pki/authorities/local/root.crt

# Restart your browser to pick up the trusted certificate
```

**What This Does**:
- Caddy generates an internal Certificate Authority (CA)
- Trusting it prevents "Not Secure" warnings
- All services (OpenWebUI, Jupyter, etc.) use certificates signed by this CA

**Optional**: You can skip this and accept security exceptions, but it's annoying.

### 5. Start All Services

```bash
docker compose up -d
```

**What This Does**:
- Pulls Docker images (first time only, ~10-15GB total)
- Starts all services in detached mode
- Creates data directories in `./data/`

**First-time download** may take several minutes depending on connection speed.

### 6. Verify Services

Check all services are running:

```bash
docker compose ps
```

Expected output:
```
NAME        IMAGE                                      STATUS
caddy       caddy:latest                               Up
jupyter     jupyter/scipy-notebook:latest              Up
kokoro-tts  ghcr.io/remsky/kokoro-fastapi-cpu:latest  Up
openwebui   ghcr.io/open-webui/open-webui:main        Up
searxng     searxng/searxng:latest                     Up
watchtower  nickfedor/watchtower:latest                Up
```

### 7. Access Services

Open in your browser:

```bash
# OpenWebUI (create account on first visit)
open https://openwebui.home.arpa

# Jupyter (use token from .env)
open https://jupyter.home.arpa

# Kokoro TTS web interface
open https://kokoro.home.arpa/web

# SearXNG search engine
open https://search.home.arpa
```

### 8. Configure OpenWebUI

First-time OpenWebUI setup:

1. **Create Admin Account**:
   - Navigate to `https://openwebui.home.arpa`
   - Create your admin account (first user is admin)

2. **Verify Ollama/oMLX Connection**:
   - Check that models are available
   - If not, configure connection in Settings

3. **Optional - Configure Integrations**:
   - [Web Search (SearXNG)](../services/searxng.md)
   - [Text-to-Speech (Kokoro)](../services/kokoro-tts.md)
   - [Code Interpreter (Jupyter)](../services/jupyter.md)

## Post-Setup

### Update Firewall (for LAN access)

If you used `--lan` flag:

```bash
# Allow ports 80 and 443
# Settings → Network → Firewall
```

### Regular Updates

Watchtower automatically updates services daily at 04:00. Manual update:

```bash
docker compose pull
docker compose up -d
```

### Backup Important Data

Back up these directories regularly:

```bash
./data/openwebui/  # Chats, documents, user data
./data/jupyter/    # Notebooks
.env               # Secrets
```

## Verification Checklist

- [ ] All services show "Up" in `docker compose ps`
- [ ] Can access OpenWebUI at `https://openwebui.home.arpa`
- [ ] Can access Jupyter at `https://jupyter.home.arpa`
- [ ] Can access Kokoro at `https://kokoro.home.arpa/web`
- [ ] Can access SearXNG at `https://search.home.arpa`
- [ ] No certificate warnings in browser (if CA trusted)
- [ ] OpenWebUI shows available models
- [ ] Created admin account in OpenWebUI

## Troubleshooting

### Services Won't Start

```bash
# Check logs
docker compose logs

# Check for port conflicts
lsof -i :80
lsof -i :443
```

### Can't Access Services

1. Verify hosts file:
   ```bash
   grep homelab /etc/hosts
   ```

2. Re-run setup script:
   ```bash
   sudo bash scripts/setup-hosts.sh
   ```

3. Check services are running:
   ```bash
   docker compose ps
   ```

### Certificate Warnings Persist

1. Verify CA certificate was added:
   ```bash
   security find-certificate -c "Caddy Local Authority" -a
   ```

2. Restart browser completely

3. Clear browser cache

### Ollama/oMLX Not Connecting

See [OpenWebUI documentation](../services/openwebui.md#troubleshooting) for connection issues.

## Next Steps

- [Configure OpenWebUI Integrations](../services/openwebui.md)
- [Set up Jupyter Code Interpreter](../services/jupyter.md#code-interpreter-integration)
- [Explore Kokoro TTS Voices](../services/kokoro-tts.md#available-voices)
- [Learn about Networking](networking.md)

## Related Documentation

- [Networking & TLS](networking.md)
- [OpenWebUI Guide](../services/openwebui.md)
- [Troubleshooting](../troubleshooting.md)
