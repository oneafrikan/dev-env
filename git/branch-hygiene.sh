#!/usr/bin/env bash
# ─────────────────────────────────────────────
# git/branch-hygiene.sh — prune merged and stale branches
# ─────────────────────────────────────────────
set -euo pipefail

DEV_ENV="${DEV_ENV:-$HOME/.dev-env}"
STALE_DAYS=30

log()  { echo "  [branch-hygiene] $1"; }
ok()   { echo "  ✓ $1"; }
warn() { echo "  ⚠ $1"; }

REPOS=(
  "$HOME/project-a"
  "$HOME/project-b"
  "$HOME/project-c"
  "$DEV_ENV"
)

for ROOT in "${REPOS[@]}"; do
  [[ ! -d "$ROOT/.git" ]] && continue
  REPO_NAME=$(basename "$ROOT")
  echo ""
  echo "── $REPO_NAME ──────────────────────────"

  # Prune stale remote tracking branches
  git -C "$ROOT" remote prune origin 2>/dev/null && log "Remote tracking refs pruned"

  # Default branch detection
  DEFAULT=$(git -C "$ROOT" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | \
    sed 's@^refs/remotes/origin/@@' || echo "main")

  # Merged branches (excluding current and default)
  MERGED=$(git -C "$ROOT" branch --merged "$DEFAULT" 2>/dev/null | \
    grep -vE "^\*|^  (main|master|$DEFAULT)$" | sed 's/^  //' || true)

  if [[ -n "$MERGED" ]]; then
    while IFS= read -r BRANCH; do
      [[ -z "$BRANCH" ]] && continue
      read -r -p "  Delete merged branch '$BRANCH' in $REPO_NAME? [y/N] " CHOICE
      if [[ "$CHOICE" == "y" || "$CHOICE" == "Y" ]]; then
        git -C "$ROOT" branch -d "$BRANCH"
        ok "Deleted: $BRANCH"
      else
        log "Kept: $BRANCH"
      fi
    done <<< "$MERGED"
  else
    ok "No merged branches to clean"
  fi

  # Stale branches (no commits in STALE_DAYS days)
  STALE=$(git -C "$ROOT" branch 2>/dev/null | sed 's/^[ *]*//' | while read -r B; do
    LAST=$(git -C "$ROOT" log -1 --format="%ct" "$B" 2>/dev/null || echo 0)
    CUTOFF=$(date -v-${STALE_DAYS}d +%s 2>/dev/null || date -d "$STALE_DAYS days ago" +%s)
    [[ "$LAST" -lt "$CUTOFF" ]] && echo "$B"
  done | grep -vE "^(main|master|$DEFAULT)$" || true)

  if [[ -n "$STALE" ]]; then
    warn "Branches with no commits in $STALE_DAYS days:"
    while IFS= read -r BRANCH; do
      [[ -z "$BRANCH" ]] && continue
      LAST_DATE=$(git -C "$ROOT" log -1 --format="%ar" "$BRANCH" 2>/dev/null || echo "unknown")
      echo "    $BRANCH (last commit: $LAST_DATE)"
      read -r -p "    Delete? [y/N] " CHOICE
      if [[ "$CHOICE" == "y" || "$CHOICE" == "Y" ]]; then
        git -C "$ROOT" branch -D "$BRANCH"
        ok "Deleted: $BRANCH"
      fi
    done <<< "$STALE"
  else
    ok "No stale branches found"
  fi
done

echo ""
ok "Branch hygiene complete"
