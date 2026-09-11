#!/usr/bin/env bash
# ─────────────────────────────────────────────
# git/standup.sh — summarise yesterday's commits across all repos
# Usage: standup.sh [--raw]  (--raw skips LLM, outputs git log only)
# ─────────────────────────────────────────────
set -euo pipefail

DEV_ENV="${DEV_ENV:-$HOME/.dev-env}"

RAW=false
[[ "${1:-}" == "--raw" ]] && RAW=true

CONTEXT_ROOTS=(
  "$HOME/project-a"
  "$HOME/project-b"
  "$HOME/Obsidian/MyVault"
  "$HOME/project-c"
  "$DEV_ENV"
)

GIT_USER=$(git config --global user.name 2>/dev/null || echo "")
SINCE="yesterday 9am"

ALL_LOG=""

for ROOT in "${CONTEXT_ROOTS[@]}"; do
  [[ ! -d "$ROOT/.git" ]] && continue
  REPO_NAME=$(basename "$ROOT")

  LOG=$(git -C "$ROOT" log \
    --since="$SINCE" \
    --oneline \
    ${GIT_USER:+--author="$GIT_USER"} \
    2>/dev/null || true)

  if [[ -n "$LOG" ]]; then
    ALL_LOG+="=== $REPO_NAME ==="$'\n'"$LOG"$'\n\n'
  fi
done

if [[ -z "$ALL_LOG" ]]; then
  echo "  No commits found since $SINCE"
  exit 0
fi

# Print raw git log
echo ""
echo "$ALL_LOG"

# Pipe through LLM unless --raw
if [[ "$RAW" == false ]]; then
  echo "── AI summary ───────────────────────────"
  echo "$ALL_LOG" | "$DEV_ENV/llm/run.sh" -t standup 2>/dev/null || \
    echo "  (LLM unavailable)"
fi
