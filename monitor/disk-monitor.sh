#!/usr/bin/env bash
# ─────────────────────────────────────────────
# monitor/disk-monitor.sh — check disk usage
# Usage: disk-monitor [--warn PERCENT] [--crit PERCENT]
# ─────────────────────────────────────────────
set -euo pipefail

DEV_ENV="${DEV_ENV:-$HOME/.dev-env}"
WARN_THRESHOLD=80
CRIT_THRESHOLD=90
YELLOW='\033[1;33m'; RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'

while [[ $# -gt 0 ]]; do
  case "$1" in
    --warn) WARN_THRESHOLD="$2"; shift 2 ;;
    --crit) CRIT_THRESHOLD="$2"; shift 2 ;;
    *) shift ;;
  esac
done

CRITICAL_HIT=0

check_volume() {
  local LABEL="$1"
  local PATH_="$2"

  [[ ! -d "$PATH_" ]] && return

  # Get usage %
  if [[ "$(uname -s)" == "Darwin" ]]; then
    PCT=$(df -h "$PATH_" | awk 'NR==2 {gsub(/%/,"",$5); print $5}')
    AVAIL=$(df -h "$PATH_" | awk 'NR==2 {print $4}')
    TOTAL=$(df -h "$PATH_" | awk 'NR==2 {print $2}')
  else
    PCT=$(df -h "$PATH_" | awk 'NR==2 {gsub(/%/,"",$5); print $5}')
    AVAIL=$(df -h "$PATH_" | awk 'NR==2 {print $4}')
    TOTAL=$(df -h "$PATH_" | awk 'NR==2 {print $2}')
  fi

  # Build bar
  BAR_WIDTH=20
  FILLED=$(( PCT * BAR_WIDTH / 100 ))
  BAR=$(printf '%*s' "$FILLED" '' | tr ' ' '█')$(printf '%*s' "$((BAR_WIDTH - FILLED))" '' | tr ' ' '░')

  if [[ "$PCT" -ge "$CRIT_THRESHOLD" ]]; then
    printf "  ${RED}✗${NC} %-20s  [%s] %3d%%  (%s/%s free)  ${RED}CRITICAL${NC}\n" \
      "$LABEL" "$BAR" "$PCT" "$AVAIL" "$TOTAL"
    CRITICAL_HIT=1
    "$DEV_ENV/monitor/alert-router.sh" \
      --severity crit \
      --source disk-monitor \
      --message "$LABEL at ${PCT}% — only ${AVAIL} free" 2>/dev/null || true
  elif [[ "$PCT" -ge "$WARN_THRESHOLD" ]]; then
    printf "  ${YELLOW}⚠${NC} %-20s  [%s] %3d%%  (%s/%s free)  ${YELLOW}WARNING${NC}\n" \
      "$LABEL" "$BAR" "$PCT" "$AVAIL" "$TOTAL"
  else
    printf "  ${GREEN}✓${NC} %-20s  [%s] %3d%%  (%s/%s free)\n" \
      "$LABEL" "$BAR" "$PCT" "$AVAIL" "$TOTAL"
  fi
}

echo ""
echo "  Disk usage (warn=${WARN_THRESHOLD}%, crit=${CRIT_THRESHOLD}%):"
echo ""

check_volume "/" "/"
check_volume "~" "$HOME"

# NAS mounts
for MOUNT in "$HOME/nas/"*/; do
  [[ -d "$MOUNT" ]] && check_volume "nas/$(basename "$MOUNT")" "$MOUNT"
done

echo ""
[[ "$CRITICAL_HIT" -eq 1 ]] && exit 1 || exit 0
