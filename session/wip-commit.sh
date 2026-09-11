#!/usr/bin/env bash
# ─────────────────────────────────────────────
# session/wip-commit.sh — wip commit all dirty context repos
# ─────────────────────────────────────────────
set -euo pipefail

DEV_ENV="${DEV_ENV:-$HOME/.dev-env}"

ok()   { echo "  ✓ $1"; }
warn() { echo "  ⚠ $1"; }

CONTEXT_ROOTS=(
  "$HOME/project-a"
  "$HOME/project-b"
  "$HOME/Obsidian/MyVault"
  "$HOME/project-c"
  "$DEV_ENV"
)

COMMITTED=0

for ROOT in "${CONTEXT_ROOTS[@]}"; do
  [[ ! -d "$ROOT" ]] && continue
  [[ ! -d "$ROOT/.git" ]] && continue

  # Check for uncommitted changes
  if git -C "$ROOT" status --porcelain | grep -q .; then
    REPO_NAME=$(basename "$ROOT")
    git -C "$ROOT" add -A
    WIP_MSG="wip: $(date '+%Y-%m-%d %H:%M')"
    git -C "$ROOT" commit -m "$WIP_MSG"
    ok "Committed: $REPO_NAME — \"$WIP_MSG\""
    COMMITTED=$((COMMITTED + 1))
  fi
done

if [[ "$COMMITTED" -eq 0 ]]; then
  echo "  Nothing to commit across all repos"
else
  ok "$COMMITTED repo(s) committed"
fi
