#!/usr/bin/env bash
# ─────────────────────────────────────────────
# data/inspect.sh — inspect a data file (CSV, Parquet, DuckDB)
# Usage: inspect <file>
# ─────────────────────────────────────────────
set -euo pipefail

DEV_ENV="${DEV_ENV:-$HOME/.dev-env}"

err() { echo "  ✗ $1" >&2; }
ok()  { echo "  ✓ $1"; }

if [[ $# -lt 1 ]]; then
  echo "Usage: inspect <file>"
  exit 1
fi

FILE="$1"

if [[ ! -f "$FILE" ]]; then
  err "File not found: $FILE"
  exit 1
fi

if ! command -v duckdb &>/dev/null; then
  err "duckdb not installed — run: brew install duckdb"
  exit 1
fi

EXT="${FILE##*.}"
echo ""
echo "  File: $FILE"
echo "  Size: $(du -sh "$FILE" | awk '{print $1}')"
echo ""

SQL_SUMMARY=""

case "${EXT,,}" in
  csv)
    echo "  Type: CSV"
    SQL_SUMMARY="
      SELECT COUNT(*) AS row_count FROM read_csv_auto('$FILE');
      DESCRIBE SELECT * FROM read_csv_auto('$FILE');
      SELECT * FROM read_csv_auto('$FILE') LIMIT 5;
    "
    ;;
  parquet)
    echo "  Type: Parquet"
    SQL_SUMMARY="
      SELECT COUNT(*) AS row_count FROM read_parquet('$FILE');
      DESCRIBE SELECT * FROM read_parquet('$FILE');
      SELECT * FROM read_parquet('$FILE') LIMIT 5;
    "
    ;;
  db|duckdb)
    echo "  Type: DuckDB"
    duckdb "$FILE" -c ".tables"
    duckdb "$FILE" -c "
      SELECT table_name,
             estimated_size AS row_count
      FROM duckdb_tables();
    "
    echo ""
    exit 0
    ;;
  *)
    err "Unsupported file type: $EXT (supported: csv, parquet, db)"
    exit 1
    ;;
esac

# Run DuckDB inspection
INSPECT_OUTPUT=$(duckdb -c "$SQL_SUMMARY" 2>&1)
echo "$INSPECT_OUTPUT"
echo ""

# AI summary
echo "── AI summary ───────────────────────────"
echo "File: $FILE"$'\n'"$INSPECT_OUTPUT" | \
  "$DEV_ENV/llm/run.sh" -t data-summary 2>/dev/null || \
  echo "  (LLM unavailable)"
echo ""
