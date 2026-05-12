#!/usr/bin/env bash
set -euo pipefail

MARKER_START="# homelab-start"
MARKER_END="# homelab-end"
HOSTS_FILE="/etc/hosts"

HOSTNAMES=(
  openwebui.home.arpa
  openwebui
  search.home.arpa
  search
  omlx.home.arpa
  omlx
  jupyter.home.arpa
  jupyter
)

# Parse flags
LAN=false
for arg in "$@"; do
  case "$arg" in
    --lan) LAN=true ;;
  esac
done

# Require root
if [[ $EUID -ne 0 ]]; then
  echo "Error: run with sudo" >&2
  echo "  sudo bash docker/scripts/setup-hosts.sh [--lan]" >&2
  exit 1
fi

# Determine IP
if [[ "$LAN" == "true" ]]; then
  IP=$(ipconfig getifaddr en0 2>/dev/null || echo "")
  if [[ -z "$IP" ]]; then
    echo "Error: could not detect LAN IP from en0" >&2
    exit 1
  fi
else
  IP="127.0.0.1"
fi

echo "Using IP: $IP"

# Remove existing managed block if present
if grep -q "$MARKER_START" "$HOSTS_FILE"; then
  sed -i '' "/$MARKER_START/,/$MARKER_END/d" "$HOSTS_FILE"
  echo "Removed existing homelab entries"
fi

# Append new block
{
  echo ""
  echo "$MARKER_START"
  for host in "${HOSTNAMES[@]}"; do
    echo "$IP  $host"
  done
  echo "$MARKER_END"
} >> "$HOSTS_FILE"

echo "Added entries to $HOSTS_FILE:"
for host in "${HOSTNAMES[@]}"; do
  echo "  $IP  $host"
done
