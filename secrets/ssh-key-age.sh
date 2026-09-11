#!/usr/bin/env bash
# ─────────────────────────────────────────────
# secrets/ssh-key-age.sh — report SSH key ages
# ─────────────────────────────────────────────
set -euo pipefail

YELLOW='\033[1;33m'; RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
SSH_DIR="$HOME/.ssh"

echo ""
echo "  SSH key audit ($SSH_DIR):"
echo ""
printf "  %-30s %-12s %-20s %s\n" "FILE" "TYPE" "CREATED" "AGE"
printf "  %-30s %-12s %-20s %s\n" "────────────────────────────" "──────────" "──────────────────" "───────"

NOW=$(date +%s)

find "$SSH_DIR" -maxdepth 1 -type f ! -name "*.pub" ! -name "known_hosts" ! -name "config" ! -name "authorized_keys" 2>/dev/null | \
while read -r KEY; do
  FNAME=$(basename "$KEY")

  # Key type from comment in pub file if it exists
  PUBKEY="${KEY}.pub"
  if [[ -f "$PUBKEY" ]]; then
    TYPE=$(awk '{print $1}' "$PUBKEY" 2>/dev/null || echo "unknown")
    TYPE="${TYPE#ssh-}"
  else
    TYPE="unknown"
  fi

  # Age from file mtime
  if [[ "$(uname -s)" == "Darwin" ]]; then
    MTIME=$(stat -f %m "$KEY" 2>/dev/null || echo 0)
  else
    MTIME=$(stat -c %Y "$KEY" 2>/dev/null || echo 0)
  fi

  CREATED=$(date -r "$MTIME" '+%Y-%m-%d' 2>/dev/null || date -d "@$MTIME" '+%Y-%m-%d' 2>/dev/null || echo "unknown")
  AGE_DAYS=$(( (NOW - MTIME) / 86400 ))

  if [[ "$AGE_DAYS" -ge 730 ]]; then
    printf "  ${RED}%-30s${NC} %-12s %-20s ${RED}%dd — ROTATE NOW${NC}\n" "$FNAME" "$TYPE" "$CREATED" "$AGE_DAYS"
  elif [[ "$AGE_DAYS" -ge 365 ]]; then
    printf "  ${YELLOW}%-30s${NC} %-12s %-20s ${YELLOW}%dd — consider rotating${NC}\n" "$FNAME" "$TYPE" "$CREATED" "$AGE_DAYS"
  else
    printf "  ${GREEN}%-30s${NC} %-12s %-20s ${GREEN}%dd${NC}\n" "$FNAME" "$TYPE" "$CREATED" "$AGE_DAYS"
  fi
done

echo ""
