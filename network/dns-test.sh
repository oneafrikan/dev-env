#!/usr/bin/env bash
set -euo pipefail
DEV_ENV="${DEV_ENV:-$HOME/.dev-env}"
err() { echo "  ✗ $1" >&2; }
main() {
  err "NOT IMPLEMENTED: $(basename "$0")"
  echo "  See: $DEV_ENV/meta/stub-audit.sh for all pending implementations"
  exit 0
}
main "$@"
