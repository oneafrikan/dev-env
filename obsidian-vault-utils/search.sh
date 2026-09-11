#!/usr/bin/env bash
# ─────────────────────────────────────────────
# vault/search.sh — interactive search across the vault
# Usage: vsearch "query"
# ─────────────────────────────────────────────
set -euo pipefail

VAULT_ROOT="$HOME/Obsidian/MyVault"

if [[ $# -lt 1 ]]; then
  echo "Usage: vsearch \"query\""
  exit 1
fi

QUERY="$*"

if [[ ! -d "$VAULT_ROOT" ]]; then
  echo "  ✗ Vault not found at $VAULT_ROOT"
  exit 1
fi

if ! command -v rg &>/dev/null; then
  echo "  ✗ ripgrep (rg) not installed — run: brew install ripgrep"
  exit 1
fi

if ! command -v fzf &>/dev/null; then
  # No fzf — just print matches
  rg -i --no-heading -l "$QUERY" "$VAULT_ROOT" --glob "!.obsidian/" | head -30
  exit 0
fi

# fzf interactive search
SELECTED=$(rg -i --no-heading -n "$QUERY" "$VAULT_ROOT" \
  --glob "!.obsidian/" \
  --color=always \
  2>/dev/null | \
  fzf --ansi \
      --delimiter=: \
      --preview 'bat --style=numbers --color=always --highlight-line {2} {1}' \
      --preview-window 'right:60%' \
      --query "$QUERY" | \
  cut -d: -f1)

if [[ -z "$SELECTED" ]]; then
  exit 0
fi

# Open in Obsidian
RELATIVE="${SELECTED#$VAULT_ROOT/}"
ENCODED=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${RELATIVE%.md}'))")

if [[ "$(uname -s)" == "Darwin" ]]; then
  open "obsidian://open?vault=MyVault&file=${ENCODED}" 2>/dev/null || \
    open -a Obsidian "$SELECTED" 2>/dev/null
else
  echo "  Open: $SELECTED"
fi
