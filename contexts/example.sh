#!/usr/bin/env bash
# ─────────────────────────────────────────────
# contexts/example.sh — template for a context activation script
# Copy to contexts/<name>.sh, fill in ROOT/SPACE, then: ctx <name>
# ─────────────────────────────────────────────
set -euo pipefail

DEV_ENV="${DEV_ENV:-$HOME/.dev-env}"
source "$DEV_ENV/lib/platform.sh"
source "$DEV_ENV/shell/functions.zsh"

log()  { echo "  [example] $1"; }
ok()   { echo "  ✓ $1"; }
warn() { echo "  ⚠ $1"; }
err()  { echo "  ✗ $1" >&2; }

ROOT="$HOME/my-project"      # <- your project root
SPACE=1                      # <- macOS Space number (see hammerspoon/init.lua)
WORKSPACE="$ROOT/my-project.code-workspace"

# ── 1. Validate project root ──────────────────
if [[ ! -d "$ROOT" ]]; then
  err "$ROOT not found. Is the project checked out?"
  exit 1
fi

# ── 2. Source .env if present ─────────────────
[[ -f "$ROOT/.env" ]] && set -a && source "$ROOT/.env" && set +a

# ── 3. Switch macOS Space ─────────────────────
log "Switching to Space $SPACE..."
platform_switch_space "$SPACE"

# ── 4. Open workspace in supacode (optional — skip if you don't use it) ──
if command -v supacode &>/dev/null; then
  log "Setting up supacode workspace..."
  sc_open "$ROOT" \
    "claude" \
    "tail -f '$ROOT/logs/app.log' 2>/dev/null || echo 'No log yet'" \
    "git -C '$ROOT' status -sb && git -C '$ROOT' log --oneline -10"
  supacode open
  ok "Context ready — supacode focused on $ROOT"
fi

# ── 5. Open Cursor workspace ──────────────────
if [[ -f "$WORKSPACE" ]]; then
  log "Opening Cursor workspace..."
  platform_open_workspace "$WORKSPACE"
else
  log "No .code-workspace found — opening folder"
  platform_open_workspace "$ROOT"
fi
