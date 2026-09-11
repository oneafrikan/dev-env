#!/usr/bin/env bash
# ─────────────────────────────────────────────
# fabric/install.sh — install fabric and link patterns
# ─────────────────────────────────────────────
set -euo pipefail

DEV_ENV="${DEV_ENV:-$HOME/.dev-env}"
FABRIC_PATTERNS_DIR="$HOME/.config/fabric/patterns"
LOCAL_PATTERNS="$DEV_ENV/fabric/patterns"

ok()   { echo "  ✓ $1"; }
warn() { echo "  ⚠ $1"; }
err()  { echo "  ✗ $1" >&2; }

# ── Install fabric ────────────────────────────
if command -v fabric &>/dev/null; then
  ok "fabric already installed ($(fabric --version 2>/dev/null | head -1 || echo 'unknown version'))"
else
  if ! command -v go &>/dev/null; then
    err "go not installed — install Go first, then re-run this script"
    echo "  Install Go: brew install go"
    exit 1
  fi
  echo "  Installing fabric..."
  go install github.com/danielmiessler/fabric@latest
  ok "fabric installed"
fi

# ── Setup patterns directory ──────────────────
mkdir -p "$FABRIC_PATTERNS_DIR"
mkdir -p "$LOCAL_PATTERNS"

# ── Symlink any custom patterns ───────────────
LINKED=0
for PATTERN_FILE in "$LOCAL_PATTERNS"/*.md; do
  [[ ! -f "$PATTERN_FILE" ]] && continue
  NAME=$(basename "$PATTERN_FILE" .md)
  TARGET="$FABRIC_PATTERNS_DIR/$NAME"
  if [[ ! -e "$TARGET" ]]; then
    ln -s "$PATTERN_FILE" "$TARGET"
    ok "Linked pattern: $NAME"
    LINKED=$((LINKED + 1))
  fi
done

if [[ "$LINKED" -eq 0 ]]; then
  ok "No custom patterns to link (add .md files to fabric/patterns/)"
fi

# ── Update fabric patterns ────────────────────
if command -v fabric &>/dev/null; then
  echo "  Updating fabric patterns from GitHub..."
  fabric --updatepatterns 2>/dev/null && ok "Patterns updated" || \
    warn "Pattern update failed — check network connection"
fi

ok "Fabric setup complete"
