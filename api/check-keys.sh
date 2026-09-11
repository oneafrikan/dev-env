#!/usr/bin/env bash
# ─────────────────────────────────────────────
# api/check-keys.sh — verify API connectivity and key presence
# ─────────────────────────────────────────────
set -euo pipefail

DEV_ENV="${DEV_ENV:-$HOME/.dev-env}"
GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'

pass() { printf "  ${GREEN}✓${NC} %s\n" "$1"; }
fail() { printf "  ${RED}✗${NC} %s\n" "$1"; FAILURES=$((FAILURES + 1)); }

FAILURES=0

echo ""
echo "  API & key checks:"
echo ""

# ── 1Password CLI ─────────────────────────────
if command -v op &>/dev/null; then
  if op whoami &>/dev/null; then
    pass "1Password CLI (op) — signed in as $(op whoami 2>/dev/null | head -1)"
  else
    fail "1Password CLI — not signed in (run: op signin)"
  fi
else
  fail "1Password CLI (op) — not installed"
fi

# ── Anthropic via llm ─────────────────────────
if command -v llm &>/dev/null; then
  ANTHROPIC_TEST=$(llm -m claude-haiku-4.5 "ping" 2>&1 | head -c 50 || true)
  if [[ "$ANTHROPIC_TEST" != *"Error"* && "$ANTHROPIC_TEST" != *"error"* && -n "$ANTHROPIC_TEST" ]]; then
    pass "Anthropic API (claude-haiku-4.5) — reachable"
  else
    fail "Anthropic API — check key with: llm keys set anthropic"
  fi
else
  fail "llm CLI not installed — run bootstrap.sh"
fi

# ── .env files in context roots ───────────────
CONTEXT_ROOTS=(
  "$HOME/project-a"
  "$HOME/project-b"
  "$HOME/project-c"
)

for ROOT in "${CONTEXT_ROOTS[@]}"; do
  REPO_NAME=$(basename "$ROOT")
  if [[ -f "$ROOT/.env" ]]; then
    pass ".env present — $REPO_NAME"
  else
    fail ".env missing — $REPO_NAME (create $ROOT/.env)"
  fi
done

echo ""
if [[ "$FAILURES" -gt 0 ]]; then
  echo "  $FAILURES check(s) failed"
  exit 1
else
  echo "  All checks passed"
fi
echo ""
