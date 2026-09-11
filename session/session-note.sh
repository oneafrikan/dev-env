#!/usr/bin/env bash
# ─────────────────────────────────────────────
# session/session-note.sh — generate and save a vault session note
# ─────────────────────────────────────────────
set -euo pipefail

DEV_ENV="${DEV_ENV:-$HOME/.dev-env}"
VAULT_ROOT="$HOME/Obsidian/MyVault"
INBOX="$VAULT_ROOT/inbox"
NOTE_FILE="$INBOX/session-notes.md"

ok()   { echo "  ✓ $1"; }
warn() { echo "  ⚠ $1"; }
err()  { echo "  ✗ $1" >&2; }

CONTEXT_ROOTS=(
  "$HOME/project-a"
  "$HOME/project-b"
  "$HOME/project-c"
  "$DEV_ENV"
)

# ── Collect git activity since morning ────────
GIT_LOG=""
for ROOT in "${CONTEXT_ROOTS[@]}"; do
  [[ ! -d "$ROOT/.git" ]] && continue
  REPO_NAME=$(basename "$ROOT")
  LOG=$(git -C "$ROOT" log --since="today 6am" --oneline 2>/dev/null || true)
  if [[ -n "$LOG" ]]; then
    GIT_LOG+="## $REPO_NAME"$'\n'"$LOG"$'\n\n'
  fi
done

if [[ -z "$GIT_LOG" ]]; then
  GIT_LOG="No commits today"
fi

# ── Generate note via LLM ─────────────────────
DATE_HEADER="$(date '+%Y-%m-%d %H:%M')"
INPUT="Date: $DATE_HEADER"$'\n\n'"$GIT_LOG"

NOTE=$(echo "$INPUT" | "$DEV_ENV/llm/run.sh" -t session-note 2>/dev/null) || {
  warn "LLM unavailable — writing raw activity log"
  NOTE="## Session — $DATE_HEADER"$'\n\n'"$GIT_LOG"
}

# ── Append to vault inbox ─────────────────────
if [[ ! -d "$VAULT_ROOT" ]]; then
  warn "Vault not found at $VAULT_ROOT — printing note to stdout instead"
  echo "$NOTE"
  exit 0
fi

mkdir -p "$INBOX"
{
  echo ""
  echo "---"
  echo ""
  echo "$NOTE"
} >> "$NOTE_FILE"

ok "Session note appended to $NOTE_FILE"
