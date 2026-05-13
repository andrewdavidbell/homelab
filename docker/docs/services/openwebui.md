# OpenWeb UI

Web interface for interacting with Ollama and other LLM providers.

## Access

- **URL**: `https://openwebui.home.arpa` or `https://openwebui`
- **Authentication**: Enabled by default (create account on first visit)

## Features

- **Chat Interface**: Interact with local Ollama models
- **RAG (Retrieval-Augmented Generation)**: Upload documents for context
- **Web Search**: Integrated with SearXNG for real-time information
- **Text-to-Speech**: Kokoro TTS integration
- **Code Interpreter**: Execute Python code via Jupyter or Pyodide
- **Model Management**: Download and manage Ollama models
- **Multi-user Support**: User accounts and permissions

## Configuration

### Environment Variables

Set in `compose.yml`:

```yaml
environment:
  OLLAMA_BASE_URL: http://host.docker.internal:11434
  WEBUI_SECRET_KEY: "${WEBUI_SECRET_KEY}"
```

### Admin Panel Settings

Access via your profile icon → **Admin Panel** → **Settings**

**Important**: Some environment variables (like web search settings) are ignored if a database already exists. Configure these via the Admin Panel instead.

## Integrations

### Connecting to Ollama

OpenWeb UI connects to Ollama running on your host machine via `host.docker.internal:11434`. Ensure Ollama is running:

```bash
ollama list
# If not running:
ollama serve
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

### Ollama Connection Issues

If OpenWeb UI can't connect to Ollama:

1. Verify Ollama is running on the host:
   ```bash
   ollama list
   ```

2. Test connectivity from the container:
   ```bash
   docker exec openwebui curl -s http://host.docker.internal:11434/api/tags
   ```

3. Check firewall settings aren't blocking the connection

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
