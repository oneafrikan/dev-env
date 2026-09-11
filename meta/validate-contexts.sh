#!/usr/bin/env bash
# ─────────────────────────────────────────────
# meta/validate-contexts.sh — validate all context scripts
# ─────────────────────────────────────────────
set -euo pipefail

DEV_ENV="${DEV_ENV:-$HOME/.dev-env}"
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

pass() { printf "  ${GREEN}✓${NC} %s\n" "$1"; PASS=$((PASS+1)); }
fail() { printf "  ${RED}✗${NC} %s\n" "$1"; FAIL=$((FAIL+1)); }
warn() { printf "  ${YELLOW}⚠${NC} %s\n" "$1"; }

PASS=0; FAIL=0

# Context definitions: name|root|space|session
# Add one entry per contexts/<name>.sh you create.
CONTEXTS=(
  "example|$HOME/my-project|1|example"
)

echo ""
echo "  Context validation:"
echo ""

SEEN_SESSIONS=""
SEEN_SPACES=""

for ENTRY in "${CONTEXTS[@]}"; do
  CONTEXT=$(echo "$ENTRY" | cut -d'|' -f1)
  ROOT=$(echo "$ENTRY" | cut -d'|' -f2)
  SPACE=$(echo "$ENTRY" | cut -d'|' -f3)
  SESSION=$(echo "$ENTRY" | cut -d'|' -f4)
  SCRIPT="$DEV_ENV/contexts/${CONTEXT}.sh"

  echo "  ── $CONTEXT ──────────────────────────"

  # Script exists and is executable
  if [[ -x "$SCRIPT" ]]; then
    pass "Script executable: contexts/${CONTEXT}.sh"
  else
    fail "Script missing or not executable: contexts/${CONTEXT}.sh"
  fi

  # Root path exists
  if [[ -d "$ROOT" ]]; then
    pass "Root exists: $ROOT"
  else
    warn "Root not found: $ROOT (create the project directory)"
  fi

  # Session name is unique
  if echo "$SEEN_SESSIONS" | grep -qw "$SESSION"; then
    fail "Duplicate session name: $SESSION"
  else
    SEEN_SESSIONS="$SEEN_SESSIONS $SESSION"
    pass "Session name unique: $SESSION"
  fi

  # Space number is unique
  if echo "$SEEN_SPACES" | grep -qw "$SPACE"; then
    fail "Duplicate Space number: $SPACE"
  else
    SEEN_SPACES="$SEEN_SPACES $SPACE"
    pass "Space number unique: Space $SPACE"
  fi

  # Hammerspoon binding: check for switchContext(SPACE, "context") pattern
  HS_INIT="$DEV_ENV/hammerspoon/init.lua"
  if [[ -f "$HS_INIT" ]] && grep -q "switchContext($SPACE" "$HS_INIT"; then
    pass "Hammerspoon binding for Space $SPACE found"
  else
    warn "Hammerspoon binding for Space $SPACE not verified in init.lua"
  fi

  echo ""
done

echo "  Result: $PASS passed, $FAIL failed"
echo ""
[[ "$FAIL" -gt 0 ]] && exit 1 || exit 0
