# OpenWeb UI

Web interface for interacting with local LLM inference engines (oMLX, Ollama, LMStudio) and cloud providers.

## Access

- **URL**: `https://openwebui.home.arpa` or `https://openwebui`
- **Authentication**: Enabled by default (create account on first visit)

## Features

- **Chat Interface**: Interact with local LLM models from various providers
- **RAG (Retrieval-Augmented Generation)**: Upload documents for context
- **Web Search**: Integrated with SearXNG for real-time information
- **Text-to-Speech**: Kokoro TTS integration
- **Code Interpreter**: Execute Python code via Jupyter or Pyodide
- **Model Management**: Download and manage models (provider-dependent)
- **Multi-user Support**: User accounts and permissions

## Configuration

### Environment Variables

**Important**: Environment variables are **only used for initial setup** before the database exists. Once OpenWebUI has been run and the database is created, these variables are ignored.

**Configure via UI instead**: Admin Panel → Settings → Connections

Available environment variables in `compose.yml`:

```yaml
environment:
  # For Ollama-compatible APIs (Ollama, oMLX, etc.)
  OLLAMA_BASE_URL: http://host.docker.internal:11434

  # For OpenAI-compatible APIs (optional)
  # OPENAI_API_BASE_URL: http://host.docker.internal:8000
  # OPENAI_API_KEY: your-api-key-here

  WEBUI_SECRET_KEY: "${WEBUI_SECRET_KEY}"
```

### Admin Panel Configuration (Recommended)

Once OpenWebUI is running, configure connections via the UI:

1. Click your profile icon → **Admin Panel**
2. Go to **Settings** → **Connections**
3. Add/edit your inference engine connections

**This is the preferred method** as it:
- Persists in the database
- Supports multiple simultaneous connections
- Allows per-connection configuration
- Updates immediately without restart

## Integrations

### Connecting to Your Inference Engine

**Configure via UI**: Admin Panel → Settings → Connections

OpenWebUI supports multiple simultaneous connections to different inference engines. Configure them through the admin interface rather than environment variables.

**Supported Engines**:

**1. oMLX** (recommended for Apple Silicon)

oMLX provides native Apple Silicon performance with MLX framework:

```bash
# Install mlx-lm
pip install mlx-lm

# Start server (from host)
mlx_lm.server --model mlx-community/Llama-3.2-3B-Instruct-4bit --port 11434

# Or use the oMLX service if configured in this stack
# Access at: http://omlx.home.arpa
```

**Configure in OpenWebUI** (Admin Panel → Settings → Connections):
- **Name**: oMLX
- **Type**: Ollama (for Ollama-compatible) or OpenAI
- **Base URL**:
  - Using host oMLX on port 11434: `http://host.docker.internal:11434`
  - Using host oMLX on port 8000: `http://host.docker.internal:8000`
  - Using oMLX service: `http://omlx:8000`

**2. Ollama**

Cross-platform, easy setup:

```bash
# Install from ollama.ai
# Check Ollama is running
ollama list

# If not running:
ollama serve

# Pull a model
ollama pull llama3.2
```

**Configure in OpenWebUI** (Admin Panel → Settings → Connections):
- **Name**: Ollama
- **Type**: Ollama
- **Base URL**: `http://host.docker.internal:11434`

**3. LMStudio**

User-friendly GUI application:

- Download from [lmstudio.ai](https://lmstudio.ai/)
- Load a model
- Enable local server (Settings → Server)
- Note the port (often 1234 by default)

**Configure in OpenWebUI** (Admin Panel → Settings → Connections):
- **Name**: LMStudio
- **Type**: OpenAI
- **Base URL**: `http://host.docker.internal:1234` (adjust port as needed)

**4. Any OpenAI-compatible API**

Works with remote or local APIs.

**Configure in OpenWebUI** (Admin Panel → Settings → Connections):
- **Name**: Your choice
- **Type**: OpenAI
- **Base URL**: Your API endpoint
- **API Key**: If required

**Testing Connection**:
```bash
# Test from host
curl http://localhost:11434/api/tags

# Test from OpenWebUI container
docker exec openwebui curl http://host.docker.internal:11434/api/tags
```

### Web Search (SearXNG)

Configure in **Admin Panel** → **Settings** → **Web Search**:

- **Enable RAG Web Search**: On
- **Search Engine**: SearXNG
- **Query URL**: `http://searxng:8080/search?q=<query>&format=json`

### Text-to-Speech (Kokoro)

See the [Kokoro TTS guide](kokoro-tts.md) for configuration.

### Code Interpreter (Jupyter)

See the [Jupyter guide](jupyter.md#code-interpreter-integration) for configuration.

## Data Persistence

All OpenWeb UI data is stored in:
```
./data/openwebui/
```

This includes:
- User accounts and settings
- Chat history
- Uploaded documents
- Model configurations
- Cached embeddings and models

## Troubleshooting

### Can't Access OpenWeb UI

1. Check the service is running:
   ```bash
   docker compose ps openwebui
   docker logs openwebui --tail 50
   ```

2. Verify hosts file:
   ```bash
   grep openwebui /etc/hosts
   ```

3. Check Caddy is proxying correctly:
   ```bash
   docker compose logs caddy --tail 20
   ```

### Inference Engine Connection Issues

If OpenWeb UI can't connect to your inference engine:

1. **Verify your inference engine is running**:
   ```bash
   # For oMLX
   curl http://localhost:11434/api/tags

   # For Ollama
   ollama list

   # For LMStudio
   # Check LMStudio app shows server running
   ```

2. **Test connectivity from OpenWebUI container**:
   ```bash
   docker exec openwebui curl -s http://host.docker.internal:11434/api/tags
   ```

3. **Check connections in OpenWebUI UI**:
   - Admin Panel → Settings → Connections
   - Verify your inference engine is configured
   - Test the connection using the "Test Connection" button
   - Common URLs:
     - Host inference on 11434: `http://host.docker.internal:11434`
     - Host oMLX on 8000: `http://host.docker.internal:8000`
     - oMLX service in stack: `http://omlx:8000`

4. **Environment variables are ignored after first run**:
   - Don't rely on `OLLAMA_BASE_URL` or `OPENAI_API_BASE_URL` in compose.yml
   - Configure via UI (Admin Panel → Settings → Connections)

5. **Check firewall settings** aren't blocking the connection

### Web Search Not Working

1. Verify SearXNG is running:
   ```bash
   docker compose ps searxng
   docker logs searxng --tail 20
   ```

2. Test SearXNG directly:
   ```bash
   curl -s "http://search.home.arpa/search?q=test&format=json" | jq .
   ```

3. Reconfigure in Admin Panel (environment variables are ignored if DB exists)

## Advanced Configuration

### Custom Models

Add custom models in **Admin Panel** → **Settings** → **Models**

### Document Processing

Configure embedding models and chunk sizes in **Admin Panel** → **Settings** → **Documents**

### API Access

OpenWeb UI provides an API for programmatic access. See the [official documentation](https://docs.openwebui.com) for API details.

## Related Documentation

- [Jupyter Integration](jupyter.md#code-interpreter-integration)
- [Kokoro TTS Integration](kokoro-tts.md#openwebui-integration)
- [SearXNG Configuration](searxng.md)
