#!/usr/bin/env bash
# ─────────────────────────────────────────────
# session/on-end.sh — end-of-day routine
# ─────────────────────────────────────────────
set -euo pipefail

DEV_ENV="${DEV_ENV:-$HOME/.dev-env}"

log()  { echo "  [on-end] $1"; }
ok()   { echo "  ✓ $1"; }
warn() { echo "  ⚠ $1"; }

echo ""
echo "════════════════════════════════════════"
echo "  Session end — $(date '+%A %Y-%m-%d %H:%M')"
echo "════════════════════════════════════════"
echo ""

# ── 1. WIP commits across all dirty repos ─────
echo "── WIP commits ──────────────────────────"
"$DEV_ENV/session/wip-commit.sh" || warn "wip-commit encountered errors"
echo ""

# ── 2. Session note to vault ──────────────────
echo "── Session note ─────────────────────────"
"$DEV_ENV/session/session-note.sh" || warn "session-note failed — note not saved"
echo ""

# ── 3. Active tmux sessions ───────────────────
echo "── Active sessions ──────────────────────"
tmux list-sessions 2>/dev/null || echo "  No sessions running"
echo ""

echo "  ⚠  Detach sessions (prefix+d) rather than killing them."
echo "     tmux-continuum will restore them on next start."
echo ""
