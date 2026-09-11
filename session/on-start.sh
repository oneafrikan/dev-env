#!/usr/bin/env bash
# ─────────────────────────────────────────────
# session/on-start.sh — start-of-day routine
# ─────────────────────────────────────────────
set -euo pipefail

DEV_ENV="${DEV_ENV:-$HOME/.dev-env}"

log()  { echo "  [on-start] $1"; }
ok()   { echo "  ✓ $1"; }
warn() { echo "  ⚠ $1"; }

echo ""
echo "════════════════════════════════════════"
echo "  Session start — $(date '+%A %Y-%m-%d %H:%M')"
echo "════════════════════════════════════════"
echo ""

# ── 1. Repo statuses ──────────────────────────
echo "── Repo status ──────────────────────────"
"$DEV_ENV/git/multi-status.sh" || warn "multi-status failed"
echo ""

# ── 2. API key health (non-blocking) ─────────
echo "── API keys ─────────────────────────────"
"$DEV_ENV/api/check-keys.sh" || warn "check-keys returned errors (non-blocking)"
echo ""

# ── 3. Disk usage (warn only) ─────────────────
echo "── Disk ─────────────────────────────────"
"$DEV_ENV/monitor/disk-monitor.sh" || warn "disk-monitor warning — check space"
echo ""

# ── 4. Active tmux sessions ───────────────────
echo "── tmux sessions ────────────────────────"
tmux list-sessions 2>/dev/null || echo "  No sessions running"
echo ""

# ── 5. LLM standup digest ─────────────────────
echo "── Standup digest ───────────────────────"
STANDUP_RAW=$("$DEV_ENV/git/standup.sh" --raw 2>/dev/null || echo "No git activity since yesterday")
echo "$STANDUP_RAW" | "$DEV_ENV/llm/run.sh" -t standup 2>/dev/null || \
  echo "  (LLM unavailable — raw git log above)"
echo ""
