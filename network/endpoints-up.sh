#!/usr/bin/env bash
# ─────────────────────────────────────────────
# network/endpoints-up.sh — check external endpoint reachability
# Reads: network/endpoints.conf
# ─────────────────────────────────────────────
set -euo pipefail

DEV_ENV="${DEV_ENV:-$HOME/.dev-env}"
CONF="$DEV_ENV/network/endpoints.conf"
GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'

if [[ ! -f "$CONF" ]]; then
  echo "  ⚠ No endpoints.conf found at $CONF"
  echo "  Copy: cp $DEV_ENV/network/endpoints.conf.example $CONF"
  exit 0
fi

echo ""
echo "  Endpoint reachability:"
echo ""

PASS=0; FAIL=0

while IFS= read -r line; do
  [[ "$line" =~ ^#.*$ || -z "${line// /}" ]] && continue
  NAME=$(echo "$line" | awk '{print $1}')
  URL=$(echo "$line" | awk '{print $2}')

  START=$(date +%s%3N 2>/dev/null || python3 -c "import time; print(int(time.time()*1000))")
  HTTP_CODE=$(curl -sf -o /dev/null -w "%{http_code}" --max-time 5 "$URL" 2>/dev/null || echo "000")
  END=$(date +%s%3N 2>/dev/null || python3 -c "import time; print(int(time.time()*1000))")
  MS=$(( END - START ))

  if [[ "$HTTP_CODE" != "000" ]]; then
    printf "  ${GREEN}✓${NC} %-25s  %dms  (HTTP %s)\n" "$NAME" "$MS" "$HTTP_CODE"
    PASS=$((PASS + 1))
  else
    printf "  ${RED}✗${NC} %-25s  timeout/unreachable\n" "$NAME"
    FAIL=$((FAIL + 1))
  fi
done < "$CONF"

echo ""
echo "  $PASS up, $FAIL down"
echo ""
[[ "$FAIL" -gt 0 ]] && exit 1 || exit 0
