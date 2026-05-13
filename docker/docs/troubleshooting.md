# Troubleshooting Guide

Common issues and solutions for the homelab Docker stack.

## General Troubleshooting Steps

Before diving into specific issues:

1. **Check service status**:
   ```bash
   docker compose ps
   ```

2. **View logs**:
   ```bash
   # All services
   docker compose logs

   # Specific service
   docker compose logs openwebui --tail 50

   # Follow logs in real-time
   docker compose logs -f
   ```

3. **Restart services**:
   ```bash
   # Restart specific service
   docker compose restart openwebui

   # Restart all
   docker compose restart
   ```

4. **Verify networking**:
   ```bash
   # Check hosts file
   grep homelab /etc/hosts

   # Test DNS resolution
   ping openwebui.home.arpa

   # Check Docker network
   docker network inspect homelab_proxy
   ```

## Service Access Issues

### Can't Access Any Services

**Symptoms**: Services not loading in browser, connection refused

**Solutions**:

1. **Verify services are running**:
   ```bash
   docker compose ps
   # All services should show "Up"
   ```

2. **Check hosts file**:
   ```bash
   grep homelab /etc/hosts
   # Should see entries for all services
   ```

3. **Re-run hosts setup**:
   ```bash
   sudo bash scripts/setup-hosts.sh
   ```

4. **Check Caddy**:
   ```bash
   docker compose logs caddy --tail 50
   # Look for errors
   ```

5. **Test Caddy directly**:
   ```bash
   curl -k https://localhost/
   # Should get response from Caddy
   ```

6. **Check port conflicts**:
   ```bash
   lsof -i :80
   lsof -i :443
   # Ports 80 and 443 should only be used by Docker
   ```

### Certificate Warnings / "Not Secure"

**Symptoms**: Browser shows security warnings, "Not Secure" in address bar

**Solutions**:

1. **Trust Caddy CA certificate**:
   ```bash
   # Verify CA exists
   ls -la ./data/caddy/data/caddy/pki/authorities/local/root.crt

   # Trust it
   sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain \
     ./data/caddy/data/caddy/pki/authorities/local/root.crt
   ```

2. **Restart browser completely**:
   - Quit and reopen (not just close window)
   - Clear browser cache

3. **Verify CA is trusted**:
   ```bash
   security find-certificate -c "Caddy Local Authority" -a
   ```

4. **Remove and re-add CA**:
   ```bash
   # Remove
   sudo security remove-trusted-cert ./data/caddy/data/caddy/pki/authorities/local/root.crt

   # Re-add
   sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain \
     ./data/caddy/data/caddy/pki/authorities/local/root.crt
   ```

### Specific Service Not Loading

**Symptoms**: Some services work, others don't

**Solutions**:

1. **Check specific service logs**:
   ```bash
   docker compose logs [service-name] --tail 50
   ```

2. **Verify service is running**:
   ```bash
   docker compose ps [service-name]
   ```

3. **Test service directly** (bypass Caddy):
   ```bash
   # OpenWebUI
   docker exec openwebui curl http://localhost:8080

   # Jupyter
   docker exec jupyter curl http://localhost:8888

   # SearXNG
   docker exec searxng curl http://localhost:8080

   # Kokoro
   docker exec kokoro-tts curl http://localhost:8880/v1/audio/voices
   ```

4. **Restart specific service**:
   ```bash
   docker compose restart [service-name]
   ```

5. **Check Caddy configuration**:
   ```bash
   # Validate Caddyfile
   docker exec caddy caddy validate --config /etc/caddy/Caddyfile
   ```

## OpenWebUI Issues

### Can't Connect to Ollama/oMLX

**Symptoms**: No models available, connection errors

**Solutions**:

1. **Verify Ollama/oMLX is running on host**:
   ```bash
   # For Ollama
   ollama list

   # For oMLX
   curl http://localhost:11434/api/tags
   ```

2. **Test from OpenWebUI container**:
   ```bash
   docker exec openwebui curl http://host.docker.internal:11434/api/tags
   ```

3. **Check OpenWebUI logs**:
   ```bash
   docker compose logs openwebui --tail 50 | grep -i ollama
   ```

4. **Verify environment variable**:
   ```bash
   docker exec openwebui env | grep OLLAMA_BASE_URL
   # Should show: http://host.docker.internal:11434
   ```

5. **Try alternative URL**:
   ```bash
   # In OpenWebUI Settings → Connections
   # Try: http://host.docker.internal:11434
   ```

### Web Search Not Working

**Symptoms**: Web search toggle doesn't work, no search results

**Solutions**:

1. **Verify SearXNG is accessible**:
   ```bash
   docker exec openwebui curl "http://searxng:8080/search?q=test&format=json"
   ```

2. **Configure in Admin Panel**:
   - Go to Admin Panel → Settings → Web Search
   - Enable RAG Web Search: **On**
   - Engine: **SearXNG**
   - Query URL: `http://searxng:8080/search?q=<query>&format=json`

3. **Check SearXNG logs**:
   ```bash
   docker compose logs searxng --tail 50
   ```

4. **Restart both services**:
   ```bash
   docker compose restart searxng openwebui
   ```

### File Upload Issues

**Symptoms**: Can't upload files, upload fails

**Solutions**:

1. **Check file size limits**:
   - Default limit may be too small for large files
   - Configure in Admin Panel → Settings → Documents

2. **Check disk space**:
   ```bash
   df -h .
   ```

3. **Check OpenWebUI logs**:
   ```bash
   docker compose logs openwebui --tail 50 | grep -i upload
   ```

4. **Verify volume permissions**:
   ```bash
   ls -la ./data/openwebui/
   ```

## Jupyter Issues

### Can't Access Jupyter

**Symptoms**: Connection refused, authentication fails

**Solutions**:

1. **Get your token**:
   ```bash
   docker logs jupyter 2>&1 | grep "token="
   # Or check .env file
   ```

2. **Test Jupyter directly**:
   ```bash
   docker exec jupyter curl http://localhost:8888/api
   ```

3. **Check logs for errors**:
   ```bash
   docker compose logs jupyter --tail 50
   ```

4. **Restart Jupyter**:
   ```bash
   docker compose restart jupyter
   ```

### Code Interpreter Not Working

**Symptoms**: Code doesn't execute, timeouts, "Analysed" disappears

**Solutions**:

1. **Verify Jupyter is running**:
   ```bash
   docker compose ps jupyter
   ```

2. **Test connectivity from OpenWebUI**:
   ```bash
   docker exec openwebui curl http://jupyter:8888/api
   ```

3. **Check OpenWebUI Code Execution settings**:
   - Admin Panel → Settings → Code Execution
   - Engine: **Jupyter** (not Pyodide)
   - URL: `http://jupyter:8888` (not localhost, not https)
   - Token: Must match `.env` exactly

4. **Enable Code Interpreter in chat**:
   - Toggle the switch in chat controls
   - Look for "Analysed" indicator

5. **Check both service logs**:
   ```bash
   docker compose logs jupyter --tail 20
   docker compose logs openwebui --tail 20
   ```

6. **Restart both services**:
   ```bash
   docker compose restart jupyter openwebui
   ```

### Code Context Not Persisting

**Symptoms**: Variables not available between code blocks

**Cause**: Using Pyodide instead of Jupyter

**Solution**:
- Switch to Jupyter engine in Code Execution settings
- Jupyter maintains persistent context, Pyodide doesn't

## Kokoro TTS Issues

### Can't Access Web Interface

**Symptoms**: Web interface doesn't load

**Solutions**:

1. **Use HTTPS and /web path**:
   ```bash
   open https://kokoro.home.arpa/web
   # Not http, not just /
   ```

2. **Check Kokoro is running**:
   ```bash
   docker compose ps kokoro-tts
   docker logs kokoro-tts --tail 50
   ```

3. **Test API directly**:
   ```bash
   curl -sk https://kokoro.home.arpa/v1/audio/voices
   ```

4. **Accept certificate or trust CA**:
   - Either trust Caddy CA (see above)
   - Or accept security exception in browser

### OpenWebUI TTS Not Working

**Symptoms**: No audio playback, TTS fails silently

**Solutions**:

1. **Verify Kokoro is accessible from OpenWebUI**:
   ```bash
   docker exec openwebui curl http://kokoro-tts:8880/v1/audio/voices
   ```

2. **Check OpenWebUI Audio settings**:
   - Settings → Audio
   - TTS Engine: **OpenAI**
   - API Base URL: `http://kokoro-tts:8880/v1` (HTTP, not HTTPS)
   - API Key: `dummy-key`
   - TTS Model: `kokoro`
   - TTS Voice: Valid voice name (e.g., `af_heart`)

3. **Test voice is valid**:
   ```bash
   curl -sk https://kokoro.home.arpa/v1/audio/voices | jq -r '.voices' | grep af_heart
   ```

4. **Check logs**:
   ```bash
   docker compose logs kokoro-tts --tail 50
   docker compose logs openwebui --tail 50 | grep -i tts
   ```

## SearXNG Issues

### Search Not Working

**Symptoms**: No results, errors in search

**Solutions**:

1. **Test SearXNG directly**:
   ```bash
   curl -s "https://search.home.arpa/search?q=test&format=json" | jq .
   ```

2. **Check SearXNG logs**:
   ```bash
   docker compose logs searxng --tail 50
   ```

3. **Verify configuration**:
   ```bash
   cat config/searxng/settings.yml
   ```

4. **Restart SearXNG**:
   ```bash
   docker compose restart searxng
   ```

### Slow Searches

**Symptoms**: Searches take a long time

**Solutions**:

1. **Reduce enabled search engines**:
   - Edit `config/searxng/settings.yml`
   - Disable slow engines

2. **Reduce timeout**:
   ```yaml
   # In settings.yml
   engines:
     default:
       timeout: 3.0  # Reduce from default
   ```

3. **Check network connectivity**:
   - SearXNG needs internet access
   - Test: `docker exec searxng curl https://www.google.com`

## Docker Issues

### Services Keep Restarting

**Symptoms**: Services show "Restarting" in `docker compose ps`

**Solutions**:

1. **Check logs for errors**:
   ```bash
   docker compose logs [service-name]
   ```

2. **Check resource usage**:
   ```bash
   docker stats
   ```

3. **Increase Docker resources**:
   - Docker Desktop → Settings → Resources
   - Increase CPU/Memory limits

4. **Check disk space**:
   ```bash
   df -h
   ```

### Volume Permission Issues

**Symptoms**: Permission denied errors in logs

**Solutions**:

1. **Check volume ownership**:
   ```bash
   ls -la ./data/
   ```

2. **Fix permissions**:
   ```bash
   # If needed (be careful!)
   sudo chown -R $(whoami) ./data/
   ```

3. **Check SELinux/AppArmor** (usually not an issue on macOS)

### Network Issues

**Symptoms**: Containers can't communicate

**Solutions**:

1. **Check network exists**:
   ```bash
   docker network ls | grep proxy
   ```

2. **Inspect network**:
   ```bash
   docker network inspect homelab_proxy
   # Should show all services
   ```

3. **Recreate network**:
   ```bash
   docker compose down
   docker network prune
   docker compose up -d
   ```

## Performance Issues

### High CPU Usage

**Solutions**:

1. **Identify culprit**:
   ```bash
   docker stats
   ```

2. **Check logs for errors**:
   - Errors may cause retry loops

3. **Limit resources**:
   ```yaml
   # In compose.yml
   deploy:
     resources:
       limits:
         cpus: '2'
   ```

### High Memory Usage

**Solutions**:

1. **Check memory usage**:
   ```bash
   docker stats
   ```

2. **Restart memory-heavy services**:
   ```bash
   docker compose restart [service-name]
   ```

3. **Reduce concurrency**:
   - Limit concurrent operations in service settings

### Disk Space Issues

**Solutions**:

1. **Check disk usage**:
   ```bash
   du -sh ./data/*
   df -h
   ```

2. **Clean Docker images**:
   ```bash
   docker system prune -a
   ```

3. **Clear old notebooks/data**:
   - Jupyter notebooks in `./data/jupyter/`
   - OpenWebUI chats can be exported/deleted

## Getting Help

If you're still stuck:

1. **Gather diagnostic info**:
   ```bash
   docker compose ps > status.txt
   docker compose logs > logs.txt
   docker network inspect homelab_proxy > network.txt
   ```

2. **Check service-specific documentation**:
   - [OpenWebUI](services/openwebui.md)
   - [Jupyter](services/jupyter.md)
   - [Kokoro TTS](services/kokoro-tts.md)
   - [SearXNG](services/searxng.md)

3. **Search official documentation**:
   - [Docker Compose](https://docs.docker.com/compose/)
   - [Caddy](https://caddyserver.com/docs/)
   - [OpenWebUI](https://docs.openwebui.com/)

4. **Common patterns**:
   - Container name, not `localhost` for inter-container communication
   - HTTP internal, HTTPS external (via Caddy)
   - Trust Caddy CA to avoid certificate warnings

## Related Documentation

- [Initial Setup](setup/initial-setup.md)
- [Networking Guide](setup/networking.md)
- [Service Documentation](services/)
