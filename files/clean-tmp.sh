#!/usr/bin/env bash
# ─────────────────────────────────────────────
# files/clean-tmp.sh — remove Python and build artifacts
# Usage: clean-tmp.sh [--yes]  (dry-run unless --yes)
# ─────────────────────────────────────────────
set -euo pipefail

DRY_RUN=true
[[ "${1:-}" == "--yes" ]] && DRY_RUN=false

ROOTS=(
  "$HOME/project-a"
  "$HOME/project-b"
  "$HOME/project-c"
  "$HOME/.dev-env"
)

PATTERNS=(
  "__pycache__"
  ".pytest_cache"
  ".ruff_cache"
  ".mypy_cache"
  "*.pyc"
  "*.pyo"
  "dist"
  "build"
  "*.egg-info"
)

COUNT=0
BYTES=0

echo ""
if [[ "$DRY_RUN" == true ]]; then
  echo "  Dry run — pass --yes to actually delete"
fi
echo ""

for ROOT in "${ROOTS[@]}"; do
  [[ ! -d "$ROOT" ]] && continue
  for PATTERN in "${PATTERNS[@]}"; do
    while IFS= read -r ITEM; do
      [[ -z "$ITEM" ]] && continue
      if [[ -d "$ITEM" ]]; then
        SIZE=$(du -sk "$ITEM" 2>/dev/null | awk '{print $1*1024}' || echo 0)
      else
        if [[ "$(uname -s)" == "Darwin" ]]; then
          SIZE=$(stat -f %z "$ITEM" 2>/dev/null || echo 0)
        else
          SIZE=$(stat -c %s "$ITEM" 2>/dev/null || echo 0)
        fi
      fi
      BYTES=$(( BYTES + SIZE ))
      COUNT=$((COUNT + 1))
      echo "  $([ "$DRY_RUN" == true ] && echo 'would remove' || echo 'removing')  $ITEM"
      if [[ "$DRY_RUN" == false ]]; then
        rm -rf "$ITEM"
      fi
    done < <(find "$ROOT" -name "$PATTERN" ! -path "*/.venv/*" ! -path "*/.git/*" 2>/dev/null)
  done
done

SIZE_H=$(numfmt --to=iec "$BYTES" 2>/dev/null || echo "${BYTES}B")
echo ""
echo "  $COUNT item(s) — $SIZE_H"
[[ "$DRY_RUN" == true ]] && echo "  Run with --yes to delete" || echo "  ✓ Clean complete"
echo ""
