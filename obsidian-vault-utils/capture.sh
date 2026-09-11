#!/usr/bin/env bash
# ─────────────────────────────────────────────
# vault/capture.sh — capture a quick note to the vault inbox
# Usage: capture "note text"
#        echo "note" | capture
# ─────────────────────────────────────────────
set -euo pipefail

VAULT_ROOT="$HOME/Obsidian/MyVault"
INBOX="$VAULT_ROOT/inbox"
CAPTURE_FILE="$INBOX/capture.md"

if [[ ! -d "$VAULT_ROOT" ]]; then
  echo "  ✗ Vault not found at $VAULT_ROOT"
  exit 1
fi

mkdir -p "$INBOX"

# Get note from arg or stdin
if [[ $# -gt 0 ]]; then
  NOTE="$*"
elif [[ ! -t 0 ]]; then
  NOTE=$(cat)
else
  echo "Usage: capture \"note text\""
  echo "       echo \"note\" | capture"
  exit 1
fi

TIMESTAMP=$(date '+%Y-%m-%d %H:%M')
echo "- $TIMESTAMP — $NOTE" >> "$CAPTURE_FILE"
echo "  ✓ Captured: $NOTE"
