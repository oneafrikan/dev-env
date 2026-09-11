# CLAUDE.md — contexts/

## Purpose

Context activation scripts. Each script sets up a complete working environment
for one project — switches macOS Space, opens the root in supacode with named
tabs, and opens Cursor. Invoked via `ctx <name>` (see `shell/functions.zsh`).

This repo ships the mechanism and one template (`example.sh`), not any real
contexts — those are specific to your own projects. Copy `example.sh` to
`<name>.sh` and fill in your project's root path, Space number, and tabs.

## Conventions

- Each script sources `lib/platform.sh` and `shell/functions.zsh`
- Platform-specific calls (Space switch, Cursor open) use `platform_*` wrappers
- All scripts: `set -euo pipefail`, validate ROOT exists before proceeding
- Tab layout is idempotent: `sc_open` skips tab creation if >1 tab already exists
- `sc_open`/`supacode` are optional — the Space-switch and Cursor-open steps work without them

## Dependencies

- `supacode` — terminal workspace manager (optional — see `shell/functions.zsh`)
- `sc_open` / `_sc_wt` — helpers in `shell/functions.zsh`
- `lib/platform.sh` — OS abstraction
- Hammerspoon (macOS only) — Space switching

## Scripts

| Name        | Status  | Description                                    |
|-------------|---------|-------------------------------------------------|
| example.sh  | template| Copy to `<name>.sh` and fill in your own project |

## Secrets

`.env` files in each project root are sourced if present. Not committed.
