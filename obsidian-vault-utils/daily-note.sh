#!/usr/bin/env bash
# ─────────────────────────────────────────────
# vault/daily-note.sh — create or open today's daily note
# ─────────────────────────────────────────────
set -euo pipefail

VAULT_ROOT="$HOME/Obsidian/MyVault"
DAILY_DIR="$VAULT_ROOT/50-Daily-Notes"
DATE=$(date '+%Y-%m-%d')
DAY=$(date '+%A')
NOTE_FILE="$DAILY_DIR/$DATE.md"

ok()   { echo "  ✓ $1"; }
warn() { echo "  ⚠ $1"; }

if [[ ! -d "$VAULT_ROOT" ]]; then
  echo "  ✗ Vault not found at $VAULT_ROOT"
  exit 1
fi

mkdir -p "$DAILY_DIR"

if [[ -f "$NOTE_FILE" ]]; then
  warn "Note already exists — opening"
else
  cat > "$NOTE_FILE" << TEMPLATE
---
date: $DATE
day: $DAY
tags: [daily]
---

# $DATE — $DAY

## Tasks
- [ ]

## Notes


## Captures


## Log


TEMPLATE
  ok "Created: $NOTE_FILE"
fi

# Open in Obsidian
if [[ "$(uname -s)" == "Darwin" ]]; then
  ENCODED_DATE=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$DATE'))")
  open "obsidian://open?vault=MyVault&file=50-Daily-Notes%2F${ENCODED_DATE}" 2>/dev/null || \
    open -a Obsidian "$NOTE_FILE" 2>/dev/null || \
    warn "Obsidian not found — file at $NOTE_FILE"
else
  warn "Open manually: $NOTE_FILE"
fi
