#!/usr/bin/env bash
# ─────────────────────────────────────────────
# data/freshness-check.sh — check data file ages
# Usage: freshness-check [directory]
# ─────────────────────────────────────────────
set -euo pipefail

DEV_ENV="${DEV_ENV:-$HOME/.dev-env}"
YELLOW='\033[1;33m'; RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'

DIR="${1:-$HOME/project-c}"

if [[ ! -d "$DIR" ]]; then
  echo "  ✗ Directory not found: $DIR"
  exit 1
fi

echo ""
echo "  Data freshness check: $DIR"
echo ""
printf "  %-12s %-20s %-12s %s\n" "AGE" "MODIFIED" "SIZE" "FILE"
printf "  %-12s %-20s %-12s %s\n" "──────────" "──────────────────" "──────────" "────"

NOW=$(date +%s)

find "$DIR" -type f \( -name "*.parquet" -o -name "*.csv" -o -name "*.db" \) 2>/dev/null | \
while read -r FILE; do
  if [[ "$(uname -s)" == "Darwin" ]]; then
    MTIME=$(stat -f %m "$FILE" 2>/dev/null || echo 0)
    SIZE=$(stat -f %z "$FILE" 2>/dev/null || echo 0)
  else
    MTIME=$(stat -c %Y "$FILE" 2>/dev/null || echo 0)
    SIZE=$(stat -c %s "$FILE" 2>/dev/null || echo 0)
  fi

  AGE_SECS=$(( NOW - MTIME ))
  AGE_DAYS=$(( AGE_SECS / 86400 ))
  MOD_DATE=$(date -r "$MTIME" '+%Y-%m-%d %H:%M' 2>/dev/null || date -d "@$MTIME" '+%Y-%m-%d %H:%M' 2>/dev/null || echo "unknown")
  SIZE_H=$(numfmt --to=iec "$SIZE" 2>/dev/null || echo "${SIZE}B")
  RELNAME="${FILE#$DIR/}"

  if [[ "$AGE_DAYS" -ge 30 ]]; then
    printf "  ${RED}%-12s${NC} %-20s %-12s %s\n" "${AGE_DAYS}d ago" "$MOD_DATE" "$SIZE_H" "$RELNAME"
  elif [[ "$AGE_DAYS" -ge 7 ]]; then
    printf "  ${YELLOW}%-12s${NC} %-20s %-12s %s\n" "${AGE_DAYS}d ago" "$MOD_DATE" "$SIZE_H" "$RELNAME"
  else
    printf "  ${GREEN}%-12s${NC} %-20s %-12s %s\n" "${AGE_DAYS}d ago" "$MOD_DATE" "$SIZE_H" "$RELNAME"
  fi
done

echo ""
