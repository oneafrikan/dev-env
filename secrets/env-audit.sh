#!/usr/bin/env bash
# ─────────────────────────────────────────────
# secrets/env-audit.sh — check .env files are gitignored
# ─────────────────────────────────────────────
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

SEARCH_ROOTS=(
  "$HOME/project-a"
  "$HOME/project-b"
  "$HOME/project-c"
  "$HOME/.dev-env"
  "$HOME"
)

echo ""
echo "  .env audit:"
echo ""

WARNINGS=0

for ROOT in "${SEARCH_ROOTS[@]}"; do
  [[ ! -d "$ROOT" ]] && continue
  find "$ROOT" -maxdepth 3 -name ".env" -o -name ".env.*" 2>/dev/null | grep -v "/.git/" | \
  while read -r ENV_FILE; do
    REPO_DIR=$(git -C "$(dirname "$ENV_FILE")" rev-parse --show-toplevel 2>/dev/null || echo "")
    if [[ -n "$REPO_DIR" ]]; then
      IGNORED=$(git -C "$REPO_DIR" check-ignore -q "$ENV_FILE" 2>/dev/null && echo "yes" || echo "no")
      if [[ "$IGNORED" == "no" ]]; then
        printf "  ${RED}✗ NOT GITIGNORED${NC} — %s\n" "$ENV_FILE"
        WARNINGS=$((WARNINGS + 1))
      else
        printf "  ${GREEN}✓${NC} gitignored — %s\n" "$ENV_FILE"
      fi
    else
      printf "  ${YELLOW}?${NC} not in a git repo — %s\n" "$ENV_FILE"
    fi
  done
done

# ── Check git history for accidental .env commits ─
echo ""
echo "  Checking git history for accidental .env commits..."

for ROOT in "$HOME/project-a" "$HOME/project-b" "$HOME/project-c" "$HOME/.dev-env"; do
  [[ ! -d "$ROOT/.git" ]] && continue
  REPO_NAME=$(basename "$ROOT")
  HISTORY_HITS=$(git -C "$ROOT" log --all --full-history -- "**/.env" "*.env" ".env" 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$HISTORY_HITS" -gt 0 ]]; then
    printf "  ${RED}⚠ HISTORY:${NC} $REPO_NAME has .env in git history (%s commits) — consider git-filter-repo\n" "$HISTORY_HITS"
  else
    printf "  ${GREEN}✓${NC} $REPO_NAME — no .env in history\n"
  fi
done

echo ""
