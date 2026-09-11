#!/usr/bin/env bash
# ─────────────────────────────────────────────
# session/morning-digest.sh — daily briefing
# ─────────────────────────────────────────────
set -euo pipefail

DEV_ENV="${DEV_ENV:-$HOME/.dev-env}"

warn() { echo "  ⚠ $1"; }

echo ""
echo "════════════════════════════════════════"
echo "  Morning digest — $(date '+%A %Y-%m-%d')"
echo "════════════════════════════════════════"
echo ""

# ── Git standup ───────────────────────────────
echo "── What happened yesterday ──────────────"
STANDUP_RAW=$("$DEV_ENV/git/standup.sh" --raw 2>/dev/null || echo "No git activity")
if [[ -n "$STANDUP_RAW" ]]; then
  echo "$STANDUP_RAW" | "$DEV_ENV/llm/run.sh" -t standup 2>/dev/null || \
    { echo "$STANDUP_RAW"; warn "LLM unavailable — showing raw log"; }
else
  echo "  No commits since yesterday"
fi
echo ""

# ── Disk usage ────────────────────────────────
echo "── Disk ─────────────────────────────────"
"$DEV_ENV/monitor/disk-monitor.sh" || warn "disk check had warnings"
echo ""

# ── Cron failures (last 24h) ──────────────────
echo "── Cron health (last 24h) ───────────────"
if [[ -f "$HOME/.dev-env-alerts.log" ]]; then
  YESTERDAY=$(date -v-1d '+%Y-%m-%d' 2>/dev/null || date -d 'yesterday' '+%Y-%m-%d')
  CRON_HITS=$(grep -c "$YESTERDAY" "$HOME/.dev-env-alerts.log" 2>/dev/null || echo 0)
  if [[ "$CRON_HITS" -gt 0 ]]; then
    warn "$CRON_HITS alert(s) logged yesterday:"
    grep "$YESTERDAY" "$HOME/.dev-env-alerts.log" | tail -5
  else
    echo "  ✓ No alerts logged yesterday"
  fi
else
  echo "  ✓ No alert log found (clean)"
fi
echo ""

# ── macOS pending updates ─────────────────────
if [[ "$(uname -s)" == "Darwin" ]]; then
  echo "── macOS updates ────────────────────────"
  UPDATE_OUT=$(softwareupdate -l 2>&1)
  if echo "$UPDATE_OUT" | grep -q "No new software available"; then
    echo "  ✓ No pending macOS updates"
  else
    echo "$UPDATE_OUT" | grep -E "^\*|Title:|Version:" | head -10 || echo "  (see: softwareupdate -l)"
  fi
  echo ""
fi
