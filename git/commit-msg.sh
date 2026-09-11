#!/usr/bin/env bash
# ─────────────────────────────────────────────
# git/commit-msg.sh — AI-suggested commit message
# Usage: commit-msg [repo-path]  (defaults to current dir)
# ─────────────────────────────────────────────
set -euo pipefail

DEV_ENV="${DEV_ENV:-$HOME/.dev-env}"
REPO="${1:-$PWD}"

err() { echo "  ✗ $1" >&2; }

if [[ ! -d "$REPO/.git" ]]; then
  err "$REPO is not a git repository"
  exit 1
fi

# Capture the diff
DIFF=$(git -C "$REPO" diff HEAD 2>/dev/null)
if [[ -z "$DIFF" ]]; then
  DIFF=$(git -C "$REPO" diff --cached 2>/dev/null)
fi

if [[ -z "$DIFF" ]]; then
  err "No staged or unstaged changes found in $REPO"
  exit 1
fi

# Generate suggested message
echo ""
echo "  Generating commit message..."
SUGGESTED=$(echo "$DIFF" | "$DEV_ENV/llm/run.sh" -t commit-message 2>/dev/null) || {
  err "LLM unavailable"
  exit 1
}

echo ""
echo "  Suggested message:"
echo "  ─────────────────"
echo "  $SUGGESTED"
echo ""

# Prompt user
read -r -p "  Use this message? [y/N/e(dit)] " CHOICE
case "$CHOICE" in
  y|Y)
    git -C "$REPO" commit -m "$SUGGESTED"
    echo "  ✓ Committed"
    ;;
  e|E)
    TMPFILE=$(mktemp /tmp/commit-msg-XXXXXX)
    echo "$SUGGESTED" > "$TMPFILE"
    ${EDITOR:-nano} "$TMPFILE"
    EDITED=$(cat "$TMPFILE")
    rm -f "$TMPFILE"
    if [[ -n "$EDITED" ]]; then
      git -C "$REPO" commit -m "$EDITED"
      echo "  ✓ Committed with edited message"
    else
      echo "  Aborted — empty message"
    fi
    ;;
  *)
    echo "  Aborted"
    ;;
esac
