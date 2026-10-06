#!/usr/bin/env bash
set -euo pipefail

# Installs the OpenAI Codex CLI on macOS (Apple Silicon) via Homebrew.
#
#   Usage: install-codex.sh [--dry-run]
#
# - Install method: `brew install --cask codex` (cask name confirmed with
#   `brew info --cask codex`; there is no formula of that name).
# - Idempotent: if `codex` is already on PATH, nothing is installed (second run = no-op).
# - Never edits shell config (.zshenv / .zprofile / .zshrc) or ~/.codex/config.toml.
#   If PATH is broken the script reports it and stops.
# - Never logs in and never stores an API key. Login is interactive (browser OAuth);
#   the script only prints the command to run.
# - --dry-run prints what would happen and changes nothing.

[ "$(uname -s)" = Darwin ] || { echo "macOS only; skipping"; exit 0; }

DRY_RUN=0
case "${1:-}" in
    "")        ;;
    --dry-run) DRY_RUN=1 ;;
    *)         echo "usage: $(basename "$0") [--dry-run]" >&2; exit 2 ;;
esac

log()  { echo "  [codex] $*"; }
ok()   { echo "  ✓ $*"; }
warn() { echo "  ⚠ $*"; }
err()  { echo "  ✗ $*" >&2; }

# Locate brew: PATH first, then the Apple Silicon default prefix.
BREW="$(command -v brew || true)"
[ -n "$BREW" ] || { [ -x /opt/homebrew/bin/brew ] && BREW=/opt/homebrew/bin/brew; }
if [ -z "$BREW" ]; then
    err "Homebrew not found (checked PATH and /opt/homebrew/bin/brew); install it first"
    exit 1
fi

# --- Install (skipped when codex is already on PATH) -------------------------
if command -v codex >/dev/null 2>&1; then
    ok "codex already on PATH: $(command -v codex) — nothing to install"
elif [ "$DRY_RUN" -eq 1 ]; then
    log "DRY-RUN: would run: $BREW install --cask codex"
    log "DRY-RUN: would then verify 'codex --version' and 'zsh -c \"codex --version\"'"
    exit 0
else
    log "installing: $BREW install --cask codex"
    "$BREW" install --cask codex
fi

# --- Verify -------------------------------------------------------------------
# Brew puts the binary in <prefix>/bin; if this shell's PATH lacks it, report only.
CODEX_BIN="$(command -v codex || true)"
if [ -z "$CODEX_BIN" ]; then
    err "codex installed but not on PATH in this shell — check PATH setup (not modified by this script)"
    exit 1
fi
ok "which codex -> $CODEX_BIN"
ok "codex --version -> $("$CODEX_BIN" --version)"

# Non-login, non-interactive zsh only reads ~/.zshenv (not ~/.zprofile); this is
# the shape SSH-exec'd commands get, and has broken PATH before.
if ZSH_OUT="$(zsh -c 'codex --version' 2>&1)"; then
    ok "non-login zsh -c 'codex --version' -> $ZSH_OUT"
else
    err "codex NOT found from non-login zsh -c (PATH likely set only in ~/.zprofile): $ZSH_OUT"
    exit 1
fi

# --- Login hint (existence check only; the file's contents are never read) -----
if [ -f "$HOME/.codex/auth.json" ]; then
    ok "already logged in (~/.codex/auth.json exists)"
else
    log "not logged in yet. Run interactively (ChatGPT account, browser OAuth): codex login"
fi
