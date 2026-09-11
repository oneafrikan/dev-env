#!/usr/bin/env bash
# ─────────────────────────────────────────────
# files/find-large.sh — find files over a size threshold
# Usage: find-large [directory] [--min-size SIZE]
#        SIZE examples: 100M (default), 1G, 500K
# ─────────────────────────────────────────────
set -euo pipefail

DIR="$HOME"
MIN_SIZE="100M"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --min-size) MIN_SIZE="$2"; shift 2 ;;
    *) DIR="$1"; shift ;;
  esac
done

echo ""
echo "  Files over $MIN_SIZE in $DIR:"
echo ""

if command -v fd &>/dev/null; then
  fd --type f --size "+$MIN_SIZE" . "$DIR" 2>/dev/null | \
    while read -r FILE; do
      if [[ "$(uname -s)" == "Darwin" ]]; then
        SIZE=$(stat -f %z "$FILE" 2>/dev/null || echo 0)
      else
        SIZE=$(stat -c %s "$FILE" 2>/dev/null || echo 0)
      fi
      echo "$SIZE $FILE"
    done | sort -rn | \
    while read -r SIZE FILE; do
      SIZE_H=$(numfmt --to=iec "$SIZE" 2>/dev/null || echo "${SIZE}B")
      printf "  %-12s %s\n" "$SIZE_H" "$FILE"
    done
else
  find "$DIR" -type f -size "+$MIN_SIZE" 2>/dev/null | \
    xargs -I{} sh -c 'echo "$(du -sh "{}" 2>/dev/null | cut -f1) {}"' | \
    sort -hr | head -50 | sed 's/^/  /'
fi

echo ""
