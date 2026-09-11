# CLAUDE.md — lib/

## Purpose

Shared bash utilities sourced by other scripts. Not executed directly.

## Conventions

- All files are sourced, not executed
- No `set -euo pipefail` at top level (calling script owns that)
- Functions must be idempotent — safe to source multiple times

## Dependencies

None — lib/ is the foundation layer.

## Scripts

| Name          | Status      | Description                                        |
|---------------|-------------|----------------------------------------------------|
| platform.sh   | implemented | OS detection + wrapper functions (mac/linux)       |

## Secrets

None — lib/ contains no secrets logic.
