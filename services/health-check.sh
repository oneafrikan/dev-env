#!/usr/bin/env bash
# ─────────────────────────────────────────────
# services/health-check.sh — check local service health
# Reads: services/services.conf
# ─────────────────────────────────────────────
set -euo pipefail

DEV_ENV="${DEV_ENV:-$HOME/.dev-env}"
CONF="$DEV_ENV/services/services.conf"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

if [[ ! -f "$CONF" ]]; then
  echo "  ⚠ No services.conf found at $CONF"
  echo "  Copy the example: cp $DEV_ENV/services/services.conf.example $CONF"
  exit 0
fi

echo ""
echo "  Service health check:"
echo ""

PASS=0; FAIL=0

while IFS= read -r line; do
  # Skip comments and empty lines
  [[ "$line" =~ ^#.*$ || -z "${line// /}" ]] && continue

  NAME=$(echo "$line" | awk '{print $1}')
  TYPE=$(echo "$line" | awk '{print $2}')
  TARGET=$(echo "$line" | awk '{print $3}')

  case "$TYPE" in
    http)
      HTTP_CODE=$(curl -sf -o /dev/null -w "%{http_code}" --max-time 5 "$TARGET" 2>/dev/null || echo "000")
      if [[ "$HTTP_CODE" =~ ^[23] ]]; then
        printf "  ${GREEN}✓${NC} %-20s  %s  (%s)\n" "$NAME" "$TARGET" "$HTTP_CODE"
        PASS=$((PASS + 1))
      else
        printf "  ${RED}✗${NC} %-20s  %s  (HTTP $HTTP_CODE)\n" "$NAME" "$TARGET"
        FAIL=$((FAIL + 1))
      fi
      ;;
    process)
      if pgrep -x "$TARGET" &>/dev/null; then
        PID=$(pgrep -x "$TARGET" | head -1)
        printf "  ${GREEN}✓${NC} %-20s  process '%s' (PID %s)\n" "$NAME" "$TARGET" "$PID"
        PASS=$((PASS + 1))
      else
        printf "  ${RED}✗${NC} %-20s  process '%s' not running\n" "$NAME" "$TARGET"
        FAIL=$((FAIL + 1))
      fi
      ;;
    *)
      printf "  ${YELLOW}?${NC} %-20s  unknown type: %s\n" "$NAME" "$TYPE"
      ;;
  esac
done < "$CONF"

echo ""
echo "  $PASS up, $FAIL down"
echo ""

[[ "$FAIL" -gt 0 ]] && exit 1 || exit 0
