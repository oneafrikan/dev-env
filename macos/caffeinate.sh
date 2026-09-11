#!/usr/bin/env bash
# ─────────────────────────────────────────────
# macos/caffeinate.sh — prevent sleep with optional duration
# Usage: caffeinate [duration]  e.g. caffeinate 2h / caffeinate 30m
# macOS only
# ─────────────────────────────────────────────
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "  ⚠ macos/caffeinate.sh — macOS only, skipping"
  exit 0
fi

parse_duration() {
  local input="$1"
  if [[ "$input" =~ ^([0-9]+)h$ ]]; then
    echo $(( ${BASH_REMATCH[1]} * 3600 ))
  elif [[ "$input" =~ ^([0-9]+)m$ ]]; then
    echo $(( ${BASH_REMATCH[1]} * 60 ))
  elif [[ "$input" =~ ^([0-9]+)s$ ]]; then
    echo "${BASH_REMATCH[1]}"
  elif [[ "$input" =~ ^[0-9]+$ ]]; then
    echo "$input"
  else
    echo ""
  fi
}

DURATION_ARG="${1:-}"
SECONDS_VAL=""

if [[ -n "$DURATION_ARG" ]]; then
  SECONDS_VAL=$(parse_duration "$DURATION_ARG")
  if [[ -z "$SECONDS_VAL" ]]; then
    echo "  ✗ Invalid duration: $DURATION_ARG (use 2h, 30m, or seconds)"
    exit 1
  fi
fi

cleanup() {
  echo ""
  echo "  ✓ Caffeinate released (ran for ${ELAPSED}s)"
}

trap cleanup EXIT INT TERM

START_TIME=$(date +%s)
ELAPSED=0

if [[ -n "$SECONDS_VAL" ]]; then
  echo "  ☕ Caffeinating for $DURATION_ARG ($SECONDS_VAL seconds)..."
  caffeinate -d -u -t "$SECONDS_VAL" &
  CAFF_PID=$!
  # Countdown loop
  while kill -0 "$CAFF_PID" 2>/dev/null; do
    ELAPSED=$(( $(date +%s) - START_TIME ))
    REMAINING=$(( SECONDS_VAL - ELAPSED ))
    printf "\r  ☕ %ds remaining (%ds elapsed)  " "$REMAINING" "$ELAPSED"
    sleep 5
  done
  ELAPSED=$SECONDS_VAL
else
  echo "  ☕ Caffeinating indefinitely — Ctrl+C to stop"
  caffeinate -d -u &
  CAFF_PID=$!
  while kill -0 "$CAFF_PID" 2>/dev/null; do
    ELAPSED=$(( $(date +%s) - START_TIME ))
    printf "\r  ☕ Running for %ds  " "$ELAPSED"
    sleep 5
  done
fi
