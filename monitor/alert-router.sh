#!/usr/bin/env bash
# ─────────────────────────────────────────────
# monitor/alert-router.sh — centralised alert routing
# Usage: alert-router --severity [info|warn|crit] --message "text" [--source script-name]
#
# Routing:
#   info  → stdout only
#   warn  → stdout + ~/.dev-env-alerts.log
#   crit  → stdout + log + ntfy (if NTFY_TOPIC set)
# ─────────────────────────────────────────────
set -euo pipefail

ALERT_LOG="$HOME/.dev-env-alerts.log"
SEVERITY=""; MESSAGE=""; SOURCE="unknown"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --severity) SEVERITY="$2"; shift 2 ;;
    --message)  MESSAGE="$2";  shift 2 ;;
    --source)   SOURCE="$2";   shift 2 ;;
    *) shift ;;
  esac
done

if [[ -z "$SEVERITY" || -z "$MESSAGE" ]]; then
  echo "Usage: alert-router --severity [info|warn|crit] --message \"text\" [--source name]"
  exit 1
fi

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

case "$SEVERITY" in
  info)
    echo "  ℹ  [$SOURCE] $MESSAGE"
    ;;
  warn)
    echo "  ⚠  [$SOURCE] $MESSAGE"
    echo "$TIMESTAMP  WARN  [$SOURCE] $MESSAGE" >> "$ALERT_LOG"
    ;;
  crit)
    echo "  ✗  [$SOURCE] CRITICAL: $MESSAGE"
    echo "$TIMESTAMP  CRIT  [$SOURCE] $MESSAGE" >> "$ALERT_LOG"
    # Send via ntfy if topic is configured
    if [[ -n "${NTFY_TOPIC:-}" ]]; then
      curl -s -d "$MESSAGE" "https://ntfy.sh/$NTFY_TOPIC" \
        -H "Title: dev-env CRITICAL: $SOURCE" \
        -H "Priority: high" \
        -H "Tags: warning" &>/dev/null || \
        echo "  ⚠ ntfy delivery failed (non-fatal)"
    fi
    ;;
  *)
    echo "  ✗ Unknown severity: $SEVERITY (use info|warn|crit)"
    exit 1
    ;;
esac
