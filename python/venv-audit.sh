#!/usr/bin/env bash
# ─────────────────────────────────────────────
# python/venv-audit.sh — audit Python venvs across context roots
# ─────────────────────────────────────────────
set -euo pipefail

YELLOW='\033[1;33m'; RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'

CONTEXT_ROOTS=(
  "$HOME/project-a"
  "$HOME/project-b"
  "$HOME/project-c"
)

echo ""
echo "  Python venv audit:"
echo ""

for ROOT in "${CONTEXT_ROOTS[@]}"; do
  NAME=$(basename "$ROOT")
  [[ ! -d "$ROOT" ]] && printf "  ${YELLOW}?${NC} %-20s  (directory not found)\n" "$NAME" && continue

  VENV="$ROOT/.venv"
  if [[ ! -d "$VENV" ]]; then
    printf "  ${RED}✗${NC} %-20s  no .venv found\n" "$NAME"
    continue
  fi

  # Venv age
  if [[ "$(uname -s)" == "Darwin" ]]; then
    VENV_MTIME=$(stat -f %m "$VENV" 2>/dev/null || echo 0)
  else
    VENV_MTIME=$(stat -c %Y "$VENV" 2>/dev/null || echo 0)
  fi
  NOW=$(date +%s)
  VENV_DAYS=$(( (NOW - VENV_MTIME) / 86400 ))

  # Outdated packages
  if command -v uv &>/dev/null; then
    OUTDATED=$(uv pip list --outdated --python "$VENV/bin/python" 2>/dev/null | tail -n +3 | wc -l | tr -d ' ' || echo "?")
  else
    OUTDATED="(uv not found)"
  fi

  if [[ "$OUTDATED" == "0" ]]; then
    COLOR="$GREEN"
  elif [[ "$OUTDATED" =~ ^[0-9]+$ && "$OUTDATED" -gt 5 ]]; then
    COLOR="$RED"
  else
    COLOR="$YELLOW"
  fi

  printf "  ${GREEN}✓${NC} %-20s  venv age: %-8s outdated: ${COLOR}%s${NC}\n" \
    "$NAME" "${VENV_DAYS}d" "$OUTDATED"
done

echo ""
