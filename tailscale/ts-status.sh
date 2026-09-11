#!/usr/bin/env bash
# ts-status.sh — one-shot, read-only Tailscale overview.
# Safe to run anytime: no state changes, no sudo required.
set -euo pipefail

if ! command -v tailscale >/dev/null 2>&1; then
  echo "tailscale not found on PATH" >&2
  exit 1
fi

echo "=== version ==="
tailscale version

echo
echo "=== this node ==="
tailscale ip -4 2>/dev/null || echo "(not logged in)"

echo
echo "=== status ==="
tailscale status 2>&1 || true

echo
echo "=== netcheck ==="
tailscale netcheck 2>&1 || true
