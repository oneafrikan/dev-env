#!/usr/bin/env bash
# ─────────────────────────────────────────────
# git/multi-status.sh — status summary across all repos
# ─────────────────────────────────────────────
set -euo pipefail

DEV_ENV="${DEV_ENV:-$HOME/.dev-env}"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

REPOS=(
  "$HOME/project-a"
  "$HOME/project-b"
  "$HOME/Obsidian/MyVault"
  "$HOME/project-c"
  "$DEV_ENV"
)

printf "\n  %-22s %-18s %-12s %s\n" "REPO" "BRANCH" "AHEAD/BEHIND" "STATUS"
printf "  %-22s %-18s %-12s %s\n" "────────────────────" "────────────────" "────────────" "──────────"

for ROOT in "${REPOS[@]}"; do
  NAME=$(basename "$ROOT")
  [[ ! -d "$ROOT/.git" ]] && printf "  %-22s  (not a git repo)\n" "$NAME" && continue

  BRANCH=$(git -C "$ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "?")

  # Ahead/behind
  UPSTREAM=$(git -C "$ROOT" rev-parse --abbrev-ref "@{upstream}" 2>/dev/null || echo "")
  if [[ -n "$UPSTREAM" ]]; then
    AHEAD=$(git -C "$ROOT" rev-list --count "@{upstream}..HEAD" 2>/dev/null || echo 0)
    BEHIND=$(git -C "$ROOT" rev-list --count "HEAD..@{upstream}" 2>/dev/null || echo 0)
    AB="↑${AHEAD} ↓${BEHIND}"
  else
    AB="no remote"
  fi

  # Dirty status
  DIRTY=$(git -C "$ROOT" status --porcelain 2>/dev/null)
  UNTRACKED=$(echo "$DIRTY" | grep -c "^??" || true)
  MODIFIED=$(echo "$DIRTY" | grep -c "^[^?]" || true)

  if [[ $MODIFIED -gt 0 ]]; then
    STATUS="${YELLOW}${MODIFIED} modified${NC}"
    [[ $UNTRACKED -gt 0 ]] && STATUS+="${RED} +${UNTRACKED} untracked${NC}"
  elif [[ $UNTRACKED -gt 0 ]]; then
    STATUS="${RED}${UNTRACKED} untracked${NC}"
  else
    STATUS="${GREEN}clean${NC}"
  fi

  printf "  %-22s %-18s %-12s " "$NAME" "$BRANCH" "$AB"
  printf "${STATUS}\n"
done

echo ""
