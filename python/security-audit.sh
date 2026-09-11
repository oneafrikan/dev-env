#!/usr/bin/env bash
# ─────────────────────────────────────────────
# python/security-audit.sh — pip-audit all context venvs
# ─────────────────────────────────────────────
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

CONTEXT_ROOTS=(
  "$HOME/project-a"
  "$HOME/project-b"
  "$HOME/project-c"
)

CRITICALS=0

echo ""
echo "  Python security audit:"
echo ""

for ROOT in "${CONTEXT_ROOTS[@]}"; do
  NAME=$(basename "$ROOT")
  VENV="$ROOT/.venv"
  [[ ! -d "$VENV" ]] && printf "  ${YELLOW}⚠${NC} %-20s  no venv — skipping\n" "$NAME" && continue

  printf "  Checking %-20s..." "$NAME"

  if command -v uv &>/dev/null; then
    AUDIT_OUT=$(uv pip audit --python "$VENV/bin/python" 2>&1 || true)
  elif "$VENV/bin/pip" show pip-audit &>/dev/null 2>&1; then
    AUDIT_OUT=$("$VENV/bin/pip-audit" 2>&1 || true)
  else
    printf "  ${YELLOW}⚠${NC} pip-audit not available — install via: uv pip install pip-audit\n"
    continue
  fi

  VULN_COUNT=$(echo "$AUDIT_OUT" | grep -c "CRITICAL\|HIGH\|MEDIUM\|LOW" 2>/dev/null || echo 0)
  CRIT_COUNT=$(echo "$AUDIT_OUT" | grep -c "CRITICAL" 2>/dev/null || echo 0)

  if [[ "$VULN_COUNT" -eq 0 ]]; then
    printf "  ${GREEN}✓${NC} %-20s  no vulnerabilities\n" "$NAME"
  else
    printf "  ${RED}✗${NC} %-20s  %s vulnerability(s) — %s critical\n" "$NAME" "$VULN_COUNT" "$CRIT_COUNT"
    echo "$AUDIT_OUT" | grep -E "CRITICAL|HIGH|MEDIUM|LOW" | head -10 | sed 's/^/      /'
    CRITICALS=$((CRITICALS + CRIT_COUNT))
  fi
done

echo ""
if [[ "$CRITICALS" -gt 0 ]]; then
  printf "  ${RED}✗${NC} %s critical vulnerability(s) found — update packages immediately\n" "$CRITICALS"
  exit 1
else
  printf "  ${GREEN}✓${NC} No critical vulnerabilities\n"
fi
echo ""
