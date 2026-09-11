#!/usr/bin/env bash
# ─────────────────────────────────────────────
# services/killport.sh — kill process on a port
# Usage: killport <port>
# ─────────────────────────────────────────────
set -euo pipefail

log()  { echo "  [killport] $1"; }
warn() { echo "  ⚠ $1"; }
err()  { echo "  ✗ $1" >&2; }

if [[ $# -lt 1 ]]; then
  echo "Usage: killport <port>"
  exit 1
fi

PORT="$1"

# Find PID(s) on this port
PIDS=$(lsof -ti :"$PORT" 2>/dev/null || true)

if [[ -z "$PIDS" ]]; then
  warn "No process found on port $PORT"
  exit 0
fi

# Show what's running
echo ""
echo "  Process(es) on port $PORT:"
lsof -i :"$PORT" | grep -v "^COMMAND" | awk '{printf "    PID %-8s  %s\n", $2, $1}' | sort -u
echo ""

# Confirm
read -r -p "  Kill these process(es)? [y/N] " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  log "Aborted"
  exit 0
fi

# SIGTERM first, wait, then SIGKILL
for PID in $PIDS; do
  kill -TERM "$PID" 2>/dev/null && log "SIGTERM sent to PID $PID" || warn "Could not SIGTERM PID $PID"
done

sleep 3

# Check if still alive
STILL_ALIVE=$(lsof -ti :"$PORT" 2>/dev/null || true)
if [[ -n "$STILL_ALIVE" ]]; then
  warn "Process still alive — sending SIGKILL..."
  for PID in $STILL_ALIVE; do
    kill -KILL "$PID" 2>/dev/null && log "SIGKILL sent to PID $PID" || warn "Could not SIGKILL PID $PID"
  done
fi

echo "  ✓ Port $PORT cleared"
