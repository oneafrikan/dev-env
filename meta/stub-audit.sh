#!/usr/bin/env bash
# ─────────────────────────────────────────────
# meta/stub-audit.sh — list all NOT IMPLEMENTED scripts
# ─────────────────────────────────────────────
set -euo pipefail

DEV_ENV="${DEV_ENV:-$HOME/.dev-env}"
YELLOW='\033[1;33m'; NC='\033[0m'

echo ""
echo "  Stub audit — NOT IMPLEMENTED scripts:"
echo ""

TOTAL=0
CURRENT_DIR=""

while IFS= read -r FILE; do
  DIR=$(dirname "${FILE#$DEV_ENV/}")
  SCRIPT=$(basename "$FILE")

  if [[ "$DIR" != "$CURRENT_DIR" ]]; then
    [[ -n "$CURRENT_DIR" ]] && echo ""
    printf "  ${YELLOW}%s/${NC}\n" "$DIR"
    CURRENT_DIR="$DIR"
  fi

  # Extract description from comment header (first non-shebang, non-set comment)
  DESC=$(grep -m 1 "^# .*—" "$FILE" 2>/dev/null | sed 's/^# //' | sed 's/.*— //' || echo "")
  [[ -z "$DESC" ]] && DESC=$(head -5 "$FILE" | grep "^#" | grep -v "shebang\|set -" | tail -1 | sed 's/^# //' || echo "(no description)")

  printf "    %-35s %s\n" "$SCRIPT" "$DESC"
  TOTAL=$((TOTAL + 1))
done < <(grep -rl "NOT IMPLEMENTED" "$DEV_ENV" --include="*.sh" 2>/dev/null | \
  grep -v ".git" | grep -v "__archived" | grep -v "stub-audit.sh" | sort)

echo ""
echo "  Total stubs: $TOTAL"
echo "  Run a script to implement it, then remove the NOT IMPLEMENTED marker."
echo ""
