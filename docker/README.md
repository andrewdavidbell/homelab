# Homelab Docker Stack

Local macOS Docker Compose stack for self-hosted AI and development services.

**Important**: All services use HTTPS with internal TLS certificates provided by Caddy. Use `https://` URLs when accessing services from your browser. Trust the Caddy CA certificate to avoid security warnings (see Initial Setup).

## Services

### OpenWeb UI
- **URL**: `https://openwebui.home.arpa` or `https://openwebui`
- **Description**: Web interface for Ollama and other LLM providers
- **Features**:
  - Chat with local Ollama models
  - RAG (Retrieval-Augmented Generation) support
  - Web search integration via SearXNG
  - Text-to-speech via Kokoro TTS

### SearXNG
- **URL**: `https://search.home.arpa` or `https://search`
- **Description**: Privacy-respecting metasearch engine
- **Usage**: Integrated with OpenWeb UI for web search capabilities

### Jupyter Notebook
- **URL**: `https://jupyter.home.arpa` or `https://jupyter`
- **Description**: Interactive Python notebook environment for data science and ML experimentation
- **Image**: `jupyter/scipy-notebook:latest`
- **Features**:
  - JupyterLab interface
  - Pre-installed scientific Python stack (NumPy, SciPy, Pandas, Matplotlib)
  - Token-based authentication

#### Getting Started with Jupyter

1. Find your Jupyter token:
   ```bash
   docker logs jupyter 2>&1 | grep "token="
   ```
   Or check your `.env` file for `JUPYTER_TOKEN`

2. Access Jupyter:
   - Navigate to `https://jupyter.home.arpa`
   - Enter the token when prompted
   - Or use the URL with token: `https://jupyter.home.arpa/?token=YOUR_TOKEN`

3. Your notebooks are saved in `./data/jupyter/` and persist across container restarts

### Kokoro TTS (Text-to-Speech)
- **Web Interface**: `https://kokoro.home.arpa/web` (FastKoko UI)
- **API Documentation**: `https://kokoro.home.arpa/docs` (FastAPI Swagger UI)
- **API Endpoint**: `https://kokoro.home.arpa/v1` (external) or `http://kokoro-tts:8880/v1` (internal)
- **Description**: Fast, high-quality text-to-speech using Kokoro-82M model
- **Features**:
  - Beautiful web interface with waveform visualisation
  - OpenAI-compatible API
  - 67 voice options across multiple languages
  - Supports English, Mandarin, Hindi, and more
  - Adjustable speed (0.1x - 4.0x)
  - Audio download capability
  - Lightweight 82M parameter model optimised for CPU

**FastKoko Web UI** (`/web`) features:
- Text editor with real-time preview
- Searchable voice selection
- Interactive audio player with waveform
- Speed and language controls
- Direct audio download

#### Configure Kokoro TTS in OpenWeb UI

1. Navigate to OpenWeb UI at `https://openwebui.home.arpa`
2. Go to **Settings** → **Audio**
3. Configure TTS settings:
   - **TTS Engine**: OpenAI
   - **API Base URL**: `http://kokoro-tts:8880/v1` (container-to-container uses HTTP)
   - **API Key**: `dummy-key` (not validated)
   - **TTS Model**: `kokoro`
   - **TTS Voice**: Choose from available voices (see below)

**Important**: OpenWeb UI communicates with Kokoro internally via HTTP (`http://kokoro-tts:8880/v1`), but when accessing the Kokoro web interface from your browser, use HTTPS (`https://kokoro.home.arpa/docs`).

#### Available Voices

Popular voices include:
- `af_bella` - American Female, warm
- `af_heart` - American Female, natural (default, recommended)
- `af_sarah` - American Female, professional
- `am_adam` - American Male, authoritative
- `am_michael` - American Male, friendly
- `bf_emma` - British Female, clear
- `bm_george` - British Male, sophisticated

[Full voice list](https://huggingface.co/hexgrad/Kokoro-82M/blob/main/VOICES.md)

#### Test Kokoro TTS

**Web Interface** (easiest way):
```bash
# Open the FastKoko web UI
open https://kokoro.home.arpa/web
```

In the web interface you can:
1. Type or paste text into the editor
2. Search and select from 67 available voices
3. Adjust speed and language settings
4. Generate and play audio with waveform visualisation
5. Download the generated audio

**API Testing**:
```bash
# View interactive API documentation
open https://kokoro.home.arpa/docs

# List available voices
curl -sk https://kokoro.home.arpa/v1/audio/voices | jq -r '.voices'

# Generate speech via API
curl -sk -X POST https://kokoro.home.arpa/v1/audio/speech \
  -H "Content-Type: application/json" \
  -d '{
    "model": "kokoro",
    "input": "Hello, this is Kokoro text-to-speech.",
    "voice": "af_heart",
    "response_format": "mp3",
    "speed": 1.0
  }' \
  --output speech.mp3
```

**Note**: Use `-k` flag with curl to skip certificate verification for Caddy's internal certificates, or trust the Caddy CA (see Initial Setup).

### Caddy
- **Description**: Reverse proxy with automatic HTTPS
- **Configuration**: `Caddyfile`
- **Features**: Internal TLS certificates for all services

## Initial Setup

### 1. Configure Environment Variables

Copy the example environment file and customise:

```bash
cp .env.example .env
```

Edit `.env` and set secure values for:
- `WEBUI_SECRET_KEY` - OpenWeb UI session secret
- `SEARXNG_SECRET_KEY` - SearXNG instance secret
- `JUPYTER_TOKEN` - Jupyter authentication token

Generate secure keys with:
```bash
openssl rand -hex 32
```

### 2. Set Up Hosts File

Run the setup script to add service hostnames to `/etc/hosts`:

```bash
sudo bash scripts/setup-hosts.sh
```

For LAN access (accessible from other devices on your network):
```bash
sudo bash scripts/setup-hosts.sh --lan
```

This registers:
- `openwebui.home.arpa` / `openwebui` - OpenWeb UI chat interface
- `search.home.arpa` / `search` - SearXNG search engine
- `jupyter.home.arpa` / `jupyter` - Jupyter notebooks
- `kokoro.home.arpa` / `kokoro` - Kokoro TTS (use `/web` for UI, `/docs` for API docs)
- `omlx.home.arpa` / `omlx` - Ollama proxy

### 3. Trust Caddy CA Certificate

To avoid browser warnings for internal TLS certificates:

```bash
# Start Caddy first
docker compose up -d caddy

# Wait a moment for Caddy to generate its CA
sleep 5

# Trust the Caddy CA certificate
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain \
  ./data/caddy/data/caddy/pki/authorities/local/root.crt

# Restart browsers to pick up the new trusted certificate
```

### 4. Start All Services

```bash
docker compose up -d
```

## Service Management

```bash
# View logs for all services
docker compose logs -f

# View logs for specific service
docker compose logs -f openwebui

# Restart a service
docker compose restart openwebui

# Stop all services
docker compose down

# Update services to latest images
docker compose pull
docker compose up -d
```

## Configuration Files

- `compose.yml` - Docker Compose service definitions
- `Caddyfile` - Reverse proxy and TLS configuration
- `.env` - Environment variables and secrets (not in git)
- `config/searxng/settings.yml` - SearXNG search engine configuration

## Data Persistence

All service data is stored in `./data/`:
- `./data/caddy/` - Caddy configuration and certificates
- `./data/openwebui/` - OpenWeb UI database and models
- `./data/jupyter/` - Jupyter notebooks and workspace
- `./data/kokoro/` - Kokoro voice model cache

## Network Architecture

All services run on the `proxy` network and communicate via service names. Ollama runs on the host and is accessible to containers via `host.docker.internal:11434`.

## Troubleshooting

### Services Not Accessible

1. Check services are running:
   ```bash
   docker compose ps
   ```

2. Verify hosts file entries:
   ```bash
   grep homelab /etc/hosts
   ```

3. Re-run setup script if needed:
   ```bash
   sudo bash scripts/setup-hosts.sh
   ```

### Browser Certificate Warnings

Trust the Caddy CA certificate (see Initial Setup step 3 above).

### Ollama Connection Issues

Ensure Ollama is running on the host:
```bash
ollama list
```

If not running, start Ollama desktop app or:
```bash
ollama serve
```

### Jupyter Token Issues

Retrieve the current token:
```bash
docker logs jupyter 2>&1 | grep "token="
```

Or check your `.env` file for `JUPYTER_TOKEN`.

### Kokoro TTS Not Working

1. Check container is running:
   ```bash
   docker compose ps kokoro-tts
   docker logs kokoro-tts
   ```

2. Test the service (note: use HTTPS):
   ```bash
   # Open the web interface
   open https://kokoro.home.arpa/web

   # Or test the API endpoint
   curl -sk https://kokoro.home.arpa/v1/audio/voices
   ```

3. In OpenWeb UI, verify:
   - API Base URL is `http://kokoro-tts:8880/v1` (internal container communication uses HTTP)
   - TTS Engine is set to "OpenAI"
   - TTS Model is `kokoro`

4. If you see certificate errors in your browser:
   - Trust the Caddy CA certificate (see Initial Setup step 3)
   - Or accept the security exception for `kokoro.home.arpa`

## Auto-Updates

Watchtower automatically checks for image updates daily at 04:00 and updates containers when new versions are available.

## Security Notes

- All services use internal TLS certificates via Caddy
- Services are only accessible on localhost (127.0.0.1) by default
- Use `--lan` flag with setup script for network access (ensure firewall is configured)
- Keep secrets in `.env` file (excluded from git)
- Regularly update images with `docker compose pull`
