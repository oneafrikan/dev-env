#!/usr/bin/env bash
# ─────────────────────────────────────────────
# data/validate-export.sh — validate a data export file
# Usage: validate-export <file> [--schema schema.json]
# ─────────────────────────────────────────────
set -euo pipefail

GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'

pass() { printf "  ${GREEN}✓${NC} %s\n" "$1"; PASS=$((PASS+1)); }
fail() { printf "  ${RED}✗${NC} %s\n" "$1"; FAIL=$((FAIL+1)); }

if [[ $# -lt 1 ]]; then
  echo "Usage: validate-export <file> [--schema schema.json]"
  exit 1
fi

FILE="$1"; SCHEMA=""
[[ "${2:-}" == "--schema" && -n "${3:-}" ]] && SCHEMA="$3"

if [[ ! -f "$FILE" ]]; then
  echo "  ✗ File not found: $FILE"
  exit 1
fi

if ! command -v duckdb &>/dev/null; then
  echo "  ✗ duckdb not installed — run: brew install duckdb"
  exit 1
fi

EXT="${FILE##*.}"
case "${EXT,,}" in
  csv)     READ_CMD="read_csv_auto('$FILE')" ;;
  parquet) READ_CMD="read_parquet('$FILE')" ;;
  *)       echo "  ✗ Unsupported file type: $EXT"; exit 1 ;;
esac

PASS=0; FAIL=0
echo ""
echo "  Validating: $FILE"
echo ""

# ── Row count > 0 ─────────────────────────────
ROW_COUNT=$(duckdb -noheader -csv -c "SELECT COUNT(*) FROM $READ_CMD;" 2>/dev/null || echo 0)
if [[ "$ROW_COUNT" -gt 0 ]]; then
  pass "Row count > 0 ($ROW_COUNT rows)"
else
  fail "Row count is 0 — file is empty"
fi

# ── Get columns ───────────────────────────────
FIRST_COL=$(duckdb -noheader -csv -c "SELECT column_name FROM (DESCRIBE SELECT * FROM $READ_CMD) LIMIT 1;" 2>/dev/null || echo "")

# ── No nulls in first column ──────────────────
if [[ -n "$FIRST_COL" ]]; then
  NULL_COUNT=$(duckdb -noheader -csv -c "SELECT COUNT(*) FROM $READ_CMD WHERE \"$FIRST_COL\" IS NULL;" 2>/dev/null || echo 0)
  if [[ "$NULL_COUNT" -eq 0 ]]; then
    pass "No nulls in first column ($FIRST_COL)"
  else
    fail "$NULL_COUNT null(s) in first column ($FIRST_COL)"
  fi

  # ── No duplicate rows on first column ────────
  DUP_COUNT=$(duckdb -noheader -csv -c "
    SELECT COUNT(*) FROM (
      SELECT \"$FIRST_COL\", COUNT(*) AS n FROM $READ_CMD
      GROUP BY \"$FIRST_COL\" HAVING n > 1
    );" 2>/dev/null || echo 0)
  if [[ "$DUP_COUNT" -eq 0 ]]; then
    pass "No duplicate values in first column ($FIRST_COL)"
  else
    fail "$DUP_COUNT duplicate value(s) in first column ($FIRST_COL)"
  fi
fi

# ── Schema check ──────────────────────────────
if [[ -n "$SCHEMA" && -f "$SCHEMA" ]]; then
  if command -v jq &>/dev/null; then
    EXPECTED_COLS=$(jq -r '.columns[]' "$SCHEMA" 2>/dev/null || echo "")
    ACTUAL_COLS=$(duckdb -noheader -csv -c "SELECT column_name FROM (DESCRIBE SELECT * FROM $READ_CMD);" 2>/dev/null || echo "")
    while IFS= read -r COL; do
      [[ -z "$COL" ]] && continue
      if echo "$ACTUAL_COLS" | grep -qF "$COL"; then
        pass "Column present: $COL"
      else
        fail "Column missing: $COL"
      fi
    done <<< "$EXPECTED_COLS"
  else
    echo "  ⚠ jq not installed — skipping schema check"
  fi
fi

echo ""
echo "  Result: $PASS passed, $FAIL failed"
echo ""
[[ "$FAIL" -gt 0 ]] && exit 1 || exit 0
