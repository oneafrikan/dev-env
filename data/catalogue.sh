#!/usr/bin/env bash
# ─────────────────────────────────────────────
# data/catalogue.sh — catalogue all data files into DuckDB
# Output: ~/.dev-env-catalogue.db
# ─────────────────────────────────────────────
set -euo pipefail

CATALOGUE_DB="$HOME/.dev-env-catalogue.db"

ok()   { echo "  ✓ $1"; }
warn() { echo "  ⚠ $1"; }
err()  { echo "  ✗ $1" >&2; }

DATA_DIRS=(
  "$HOME/project-c"
  "$HOME/project-a"
)

if ! command -v duckdb &>/dev/null; then
  err "duckdb not installed — run: brew install duckdb"
  exit 1
fi

echo ""
echo "  Cataloguing data files..."

# ── Create or reset catalogue table ──────────
duckdb "$CATALOGUE_DB" -c "
  CREATE TABLE IF NOT EXISTS catalogue (
    name        VARCHAR,
    path        VARCHAR PRIMARY KEY,
    type        VARCHAR,
    size_bytes  BIGINT,
    row_count   BIGINT,
    modified_at TIMESTAMP
  );
"

ADDED=0

for DIR in "${DATA_DIRS[@]}"; do
  [[ ! -d "$DIR" ]] && continue
  find "$DIR" -type f \( -name "*.parquet" -o -name "*.csv" -o -name "*.db" \) 2>/dev/null | \
  while read -r FILE; do
    EXT="${FILE##*.}"
    SIZE=$(wc -c < "$FILE" 2>/dev/null || echo 0)

    if [[ "$(uname -s)" == "Darwin" ]]; then
      MTIME=$(stat -f %m "$FILE" 2>/dev/null || echo 0)
    else
      MTIME=$(stat -c %Y "$FILE" 2>/dev/null || echo 0)
    fi
    MOD_DATE=$(date -r "$MTIME" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -d "@$MTIME" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "unknown")

    # Row count (best effort)
    case "${EXT,,}" in
      csv)     ROW_COUNT=$(duckdb -noheader -csv -c "SELECT COUNT(*) FROM read_csv_auto('$FILE');" 2>/dev/null || echo -1) ;;
      parquet) ROW_COUNT=$(duckdb -noheader -csv -c "SELECT COUNT(*) FROM read_parquet('$FILE');" 2>/dev/null || echo -1) ;;
      db)      ROW_COUNT=-1 ;;
      *)       ROW_COUNT=-1 ;;
    esac

    NAME=$(basename "$FILE")
    duckdb "$CATALOGUE_DB" -c "
      INSERT OR REPLACE INTO catalogue
      VALUES ('$NAME', '$FILE', '${EXT,,}', $SIZE, $ROW_COUNT, '$MOD_DATE');
    " 2>/dev/null
  done
done

# ── Print summary ─────────────────────────────
echo ""
duckdb "$CATALOGUE_DB" -c "
  SELECT name, type, size_bytes, row_count, modified_at
  FROM catalogue
  ORDER BY modified_at DESC
  LIMIT 30;
"
echo ""
TOTAL=$(duckdb "$CATALOGUE_DB" -noheader -csv -c "SELECT COUNT(*) FROM catalogue;" 2>/dev/null || echo 0)
ok "Catalogued $TOTAL file(s) — db at $CATALOGUE_DB"
echo ""
