#!/usr/bin/env bash
# ─────────────────────────────────────────────
# services/ports.sh — show all listening ports
# ─────────────────────────────────────────────
set -euo pipefail

echo ""
echo "  Listening ports:"
echo ""

if [[ "$(uname -s)" == "Darwin" ]]; then
  lsof -iTCP -sTCP:LISTEN -n -P 2>/dev/null | \
    awk 'NR>1 {
      split($9, addr, ":")
      port = addr[length(addr)]
      printf "  %-8s %-10s %-8s %s\n", port, $1, $2, $8
    }' | sort -n | \
    (echo "  PORT     PROCESS    PID      PROTO" && cat) | \
    column -t
else
  ss -tlnp 2>/dev/null | awk 'NR>1 {
    split($4, addr, ":")
    port = addr[length(addr)]
    match($6, /pid=([0-9]+)/, pid_arr)
    match($6, /\"([^\"]+)\"/, name_arr)
    printf "  %-8s %-20s %s\n", port, name_arr[1], pid_arr[1]
  }' | sort -n | \
    (echo "  PORT     PROCESS              PID" && cat) | \
    column -t
fi

echo ""
