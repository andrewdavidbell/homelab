# SearXNG

Privacy-respecting metasearch engine that aggregates results from multiple search engines without tracking users.

## Access

- **URL**: `https://search.home.arpa` or `https://search`
- **Authentication**: None (can be configured)

## Features

- **Privacy-Focused**: No user tracking, no profiling, no data retention
- **Metasearch**: Aggregates results from Google, Bing, DuckDuckGo, and 70+ engines
- **Multiple Categories**: Web, images, videos, news, maps, files, science, music
- **JSON API**: Programmatic access for integration
- **OpenWebUI Integration**: Enables RAG web search in AI chats
- **Customisable**: Configure engines, preferences, and appearance

## Using SearXNG

### Web Interface

1. Navigate to `https://search.home.arpa`
2. Enter your search query
3. Select categories (Web, Images, News, etc.)
4. Browse aggregated results from multiple engines

### Search Categories

- **General**: Web pages from multiple engines
- **Images**: Image search
- **Videos**: Video search
- **News**: News articles
- **Maps**: Location and maps
- **Files**: File search (PDFs, documents)
- **Science**: Academic papers and research
- **Music**: Music and lyrics

## OpenWebUI Integration

SearXNG powers web search in OpenWebUI for real-time information retrieval.

### Configuration

**Note**: If OpenWebUI database already exists, environment variables are ignored. Configure via Admin Panel instead.

1. Navigate to `https://openwebui.home.arpa`
2. Go to **Admin Panel** → **Settings** → **Web Search**
3. Configure:
   - **Enable RAG Web Search**: On
   - **Search Engine**: SearXNG
   - **Query URL**: `http://searxng:8080/search?q=<query>&format=json`

### How It Works

When enabled, OpenWebUI will:
1. Detect when queries need real-time information
2. Query SearXNG for relevant results
3. Extract and process web content
4. Use as context for generating AI responses

This enables AI to answer questions about:
- Current events
- Recent news
- Up-to-date information
- Real-time data

## Configuration

### Settings File

SearXNG is configured via `config/searxng/settings.yml`.

**Current Configuration**:
```yaml
general:
  instance_name: "homelab-search"
  secret_key: "${SEARXNG_SECRET_KEY}"

search:
  formats:
    - html
    - json

server:
  bind_address: "0.0.0.0:8080"
  secret_key: "${SEARXNG_SECRET_KEY}"
```

### Environment Variables

Set in `.env`:
```
SEARXNG_SECRET_KEY=your-secret-key-here
```

Generate a secure key:
```bash
openssl rand -hex 32
```

### Customising Search Engines

Edit `config/searxng/settings.yml` to:
- Enable/disable specific search engines
- Adjust engine weights
- Configure categories
- Set language preferences

**Example** - Disable Google:
```yaml
engines:
  - name: google
    disabled: true
```

See [SearXNG documentation](https://docs.searxng.org/) for full configuration options.

## API Usage

### JSON Search

```bash
curl -s "https://search.home.arpa/search?q=test&format=json" | jq .
```

### Parameters

- `q` - Search query (required)
- `format` - Response format: `html` or `json`
- `categories` - Comma-separated: `general,images,videos`
- `engines` - Specific engines: `google,bing`
- `language` - Language code: `en-GB`, `en-US`
- `pageno` - Page number for pagination

### Example - Image Search

```bash
curl -s "https://search.home.arpa/search?q=cats&categories=images&format=json" | jq '.results[0]'
```

## Data Persistence

SearXNG runs stateless with configuration mounted read-only:
```
./config/searxng/ → /etc/searxng/ (read-only)
```

No search data is persisted (privacy feature).

## Troubleshooting

### Can't Access SearXNG

1. **Check service is running**:
   ```bash
   docker compose ps searxng
   docker logs searxng --tail 50
   ```

2. **Verify hosts file**:
   ```bash
   grep search /etc/hosts
   ```

3. **Test directly**:
   ```bash
   curl -sk https://search.home.arpa
   ```

### OpenWebUI Web Search Not Working

1. **Verify SearXNG is accessible from OpenWebUI**:
   ```bash
   docker exec openwebui curl -s "http://searxng:8080/search?q=test&format=json"
   ```

2. **Check OpenWebUI settings**:
   - Admin Panel → Settings → Web Search
   - URL must be `http://searxng:8080/search?q=<query>&format=json`
   - NOT `localhost`, NOT `https`

3. **Restart OpenWebUI**:
   ```bash
   docker compose restart openwebui
   ```

### Search Results Quality

- **Too many/few results**: Adjust number of engines enabled
- **Slow searches**: Disable slower engines or reduce timeout
- **Missing results**: Enable more engines in settings

### Configuration Not Updating

1. **Edit** `config/searxng/settings.yml`
2. **Restart SearXNG**:
   ```bash
   docker compose restart searxng
   ```

3. **Check logs for errors**:
   ```bash
   docker logs searxng --tail 50
   ```

## Privacy Features

- **No Logging**: Search queries are not stored
- **No Tracking**: No cookies, no user profiling
- **No Forwarding**: User data not sent to search engines
- **Encrypted**: All traffic uses HTTPS via Caddy

## Advanced Configuration

### Rate Limiting

Prevent abuse by configuring rate limits in `settings.yml`:

```yaml
server:
  limiter: true
  rate_limit: 600/minute
```

### Custom Themes

SearXNG supports custom themes. See [theme documentation](https://docs.searxng.org/admin/engines/settings.html#settings-ui).

### Adding Search Engines

Add custom engines in `settings.yml`:

```yaml
engines:
  - name: my_engine
    engine: xpath
    search_url: https://example.com/search?q={query}
    results_xpath: //div[@class='result']
    url_xpath: .//a/@href
    title_xpath: .//h3/text()
```

## Resource Usage

SearXNG is configured with minimal resource usage:

- **Logging**: Limited to 1MB max file size, 1 file
- **Capabilities**: Reduced Linux capabilities for security
- **Memory**: Typically uses 50-100MB RAM

## Related Documentation

- [OpenWebUI Integration](openwebui.md)
- [Initial Setup Guide](../setup/initial-setup.md)
- [SearXNG Official Docs](https://docs.searxng.org/)
