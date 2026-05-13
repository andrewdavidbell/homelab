# Networking & TLS

How networking, DNS, and TLS certificates work in the homelab stack.

## Overview

The homelab stack uses:
- **Caddy** - Reverse proxy with automatic HTTPS
- **Docker Networks** - Internal service communication
- **Local DNS** - `/etc/hosts` for custom domain names
- **Internal TLS** - Self-signed certificates for all services

## Architecture

```
Browser (HTTPS) → Caddy (reverse proxy) → Service (HTTP)
                    ↓
               TLS termination
```

**Flow**:
1. Browser connects to `https://openwebui.home.arpa`
2. OS resolves via `/etc/hosts` to `127.0.0.1`
3. Caddy receives HTTPS request on port 443
4. Caddy terminates TLS and proxies to `openwebui:8080` (HTTP)
5. OpenWebUI responds through Caddy back to browser

## DNS Resolution

### Hosts File Management

The `setup-hosts.sh` script manages entries in `/etc/hosts`:

```bash
# Localhost mode (default)
sudo bash scripts/setup-hosts.sh

# LAN mode (accessible from network)
sudo bash scripts/setup-hosts.sh --lan
```

**What It Does**:
- Adds entries between `# homelab-start` and `# homelab-end` markers
- Safe to run multiple times (removes old entries first)
- Supports both localhost and LAN IP modes

**Example Entries** (localhost mode):
```
# homelab-start
127.0.0.1  openwebui.home.arpa
127.0.0.1  openwebui
127.0.0.1  search.home.arpa
127.0.0.1  search
127.0.0.1  jupyter.home.arpa
127.0.0.1  jupyter
127.0.0.1  kokoro.home.arpa
127.0.0.1  kokoro
127.0.0.1  omlx.home.arpa
127.0.0.1  omlx
# homelab-end
```

### Why Custom Domains?

- **Cleaner URLs**: `openwebui.home.arpa` vs `localhost:8080`
- **Proper TLS**: Certificates work better with domain names
- **Service Isolation**: Each service has its own subdomain
- **FQDN Support**: Full `.home.arpa` domains and short names

### Manual Verification

```bash
# Check entries
grep homelab /etc/hosts

# Test resolution
ping -c 1 openwebui.home.arpa

# Should resolve to 127.0.0.1 (or your LAN IP)
```

## Docker Networking

### Proxy Network

All services run on a single Docker network named `proxy`:

```yaml
networks:
  proxy:
```

**Benefits**:
- Services communicate via container names
- Isolated from host network
- Simple service discovery

**Example**: OpenWebUI reaches Jupyter at `http://jupyter:8888` (not `localhost`).

### Container-to-Container Communication

Services communicate internally using HTTP:
- `http://jupyter:8888` - Jupyter API
- `http://searxng:8080` - SearXNG search
- `http://kokoro-tts:8880` - Kokoro TTS API

**Why HTTP internally?**
- TLS overhead unnecessary inside Docker network
- Simpler configuration
- Caddy handles HTTPS for external access

### Host Access

Services can reach the host machine via `host.docker.internal`:

```yaml
environment:
  OLLAMA_BASE_URL: http://host.docker.internal:11434
```

This allows containers to connect to services running on macOS (Ollama, oMLX, etc.).

## TLS Certificates

### Caddy Internal PKI

Caddy automatically generates:
1. **Certificate Authority (CA)** - Root certificate
2. **Service Certificates** - Signed by the internal CA

**CA Location**:
```
./data/caddy/data/caddy/pki/authorities/local/root.crt
```

**Certificate Lifecycle**:
- Caddy generates certificates on first run
- Auto-renews before expiry
- Separate certificate for each domain

### Trusting the CA

To avoid browser warnings:

```bash
# Start Caddy
docker compose up -d caddy

# Wait for CA generation
sleep 5

# Trust the CA
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain \
  ./data/caddy/data/caddy/pki/authorities/local/root.crt

# Restart browser
```

**What This Does**:
- Adds Caddy's CA to system trust store
- Browser accepts certificates signed by this CA
- No more "Not Secure" warnings

### Verifying Certificates

```bash
# Check certificate details
openssl s_client -connect openwebui.home.arpa:443 -showcerts

# Check CA in system
security find-certificate -c "Caddy Local Authority" -a
```

### Without Trusting CA

You can skip trusting the CA, but you'll need to:
- Accept security warnings in browser (every time)
- Use `curl -k` to skip verification
- See "Not Secure" in browser address bar

**For testing**: Fine to skip
**For daily use**: Better to trust the CA

## Caddy Configuration

### Caddyfile Structure

Each service gets a reverse proxy block:

```caddyfile
openwebui.home.arpa, openwebui {
    tls internal
    reverse_proxy openwebui:8080
}
```

**Components**:
- `openwebui.home.arpa, openwebui` - Domains to serve
- `tls internal` - Use internal CA (not Let's Encrypt)
- `reverse_proxy openwebui:8080` - Proxy to container

### TLS Configuration

Caddy is configured to use internal certificates only:

```caddyfile
tls internal
```

This prevents Caddy from trying to get Let's Encrypt certificates (which would fail for `.home.arpa` domains).

### Adding New Services

To add a new service:

1. **Add to Caddyfile**:
   ```caddyfile
   myservice.home.arpa, myservice {
       tls internal
       reverse_proxy myservice:8080
   }
   ```

2. **Add to hosts script**:
   ```bash
   # Edit scripts/setup-hosts.sh
   HOSTNAMES=(
     # ... existing entries
     myservice.home.arpa
     myservice
   )
   ```

3. **Restart Caddy and update hosts**:
   ```bash
   docker compose restart caddy
   sudo bash scripts/setup-hosts.sh
   ```

## Port Usage

### External Ports (Host)

- **80** (HTTP) - Caddy (redirects to HTTPS)
- **443** (HTTPS) - Caddy (all services)

### Internal Ports (Docker)

- **8080** - OpenWebUI, SearXNG
- **8880** - Kokoro TTS
- **8888** - Jupyter

Services only expose ports within Docker network, not to host.

### Checking Port Conflicts

```bash
# Check if ports 80/443 are free
lsof -i :80
lsof -i :443

# If in use, stop conflicting services
```

## LAN Access

### Enabling LAN Access

```bash
# Use your LAN IP instead of 127.0.0.1
sudo bash scripts/setup-hosts.sh --lan
```

**How It Works**:
- Detects your LAN IP (typically from `en0` interface)
- Updates `/etc/hosts` with LAN IP
- Services accessible from other devices on network

### Accessing from Other Devices

**Option 1 - Edit hosts file on each device**:

On another Mac/Linux:
```bash
# Add to /etc/hosts
192.168.1.100  openwebui.home.arpa
```

On Windows:
```
# Edit C:\Windows\System32\drivers\etc\hosts
192.168.1.100  openwebui.home.arpa
```

**Option 2 - Use IP directly** (bypasses certificate checks):
```
https://192.168.1.100/
```

### Security Considerations

When enabling LAN access:
- Services accessible to anyone on network
- Configure firewall appropriately
- Consider authentication for all services
- Only enable on trusted networks

## Firewall Configuration

macOS Firewall doesn't block by default, but to explicitly allow:

1. **System Settings** → **Network** → **Firewall**
2. Enable firewall if desired
3. Add rule for Docker: Allow incoming connections

## Troubleshooting

### Services Not Accessible

1. **Check hosts file**:
   ```bash
   grep homelab /etc/hosts
   ```

2. **Verify DNS resolution**:
   ```bash
   ping openwebui.home.arpa
   ```

3. **Check Caddy logs**:
   ```bash
   docker compose logs caddy --tail 50
   ```

4. **Test direct service access** (without Caddy):
   ```bash
   docker exec openwebui curl http://localhost:8080
   ```

### Certificate Warnings

1. **Verify CA is trusted**:
   ```bash
   security find-certificate -c "Caddy Local Authority" -a
   ```

2. **Re-trust CA**:
   ```bash
   sudo security remove-trusted-cert ./data/caddy/data/caddy/pki/authorities/local/root.crt
   sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain \
     ./data/caddy/data/caddy/pki/authorities/local/root.crt
   ```

3. **Clear browser cache and restart**

### Can't Connect to Services from Container

If a container can't reach another service:

1. **Check they're on the same network**:
   ```bash
   docker network inspect homelab_proxy
   ```

2. **Test connectivity**:
   ```bash
   docker exec openwebui ping -c 1 jupyter
   docker exec openwebui curl http://jupyter:8888/api
   ```

3. **Use container name, not localhost**:
   - ✅ `http://jupyter:8888`
   - ❌ `http://localhost:8888`

### LAN Access Not Working

1. **Verify IP detection**:
   ```bash
   ipconfig getifaddr en0
   ```

2. **Check firewall**:
   ```bash
   # Temporarily disable to test
   sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off
   ```

3. **Test from another device**:
   ```bash
   # From another device on network
   curl -k https://YOUR_LAN_IP/
   ```

## Advanced Topics

### Custom Caddy Configuration

Edit `Caddyfile` for advanced routing:

```caddyfile
openwebui.home.arpa {
    tls internal

    # Custom headers
    header {
        Strict-Transport-Security "max-age=31536000"
        X-Content-Type-Options "nosniff"
    }

    reverse_proxy openwebui:8080
}
```

### Multiple Networks

If services need isolation:

```yaml
networks:
  proxy:
  backend:

services:
  openwebui:
    networks:
      - proxy
      - backend
```

### External HTTPS

To expose publicly with Let's Encrypt:
- Set up domain pointing to your IP
- Change `tls internal` to `tls email@example.com`
- Open port 443 on router

**Warning**: Only do this if you understand the security implications.

## Related Documentation

- [Initial Setup Guide](initial-setup.md)
- [Troubleshooting](../troubleshooting.md)
- [Caddy Documentation](https://caddyserver.com/docs/)
