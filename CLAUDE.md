# CLAUDE.md — dev-env root

## What this repo is

A personal Mac/Ubuntu development environment, built as a public reference.
One command gets you into a fully-formed working context. Scripts solve real
daily friction — nothing decorative.

This is the public half of a two-repo setup: this repo has the generic,
reusable tooling; a private counterpart (not published) holds real machine
names, IPs, and personal config. `contexts/` and `scripts/iterm2-profiles/profiles/`
ship only a template — bring your own for your actual machines/projects.

## Tool stack

tmux, Hammerspoon, Cursor, iTerm2, uv, direnv, mise, atuin, just, llm, fabric, duckdb

## Primary entry point

```bash
ctx <context>   # defined in shell/functions.zsh
```

`ctx` looks up `contexts/<name>.sh` and runs it. This repo ships the mechanism
and one template (`contexts/example.sh`) — copy it, fill in your own project
root and macOS Space number, and `ctx` picks it up automatically (tab
completion too, dynamically discovered).

## Philosophy

Scripts solve real friction. Nothing decorative. If removing a script would
save time, remove it.

## Finding pending implementations

```bash
just stubs          # list all NOT IMPLEMENTED scripts
meta/stub-audit.sh  # canonical stub finder
```

## Conventions

- All scripts: `#!/usr/bin/env bash`, `set -euo pipefail`, `chmod +x`
- Logging: `log()`, `ok()`, `warn()`, `err()` — defined per script
- Secrets: 1Password CLI first, `.env` fallback, never hardcoded
- LLM calls: always via `llm/run.sh`, never call `llm` directly
- Platform abstraction: source `lib/platform.sh` for OS-dependent operations
- Stubs: contain exactly `err "NOT IMPLEMENTED: $(basename "$0")"` + exit 0
- Machine/project-specific config lives in a `*.conf`/`.json`/`.sh` file that's
  gitignored, with a `*.example` counterpart committed — see `homelab`-style
  configs in `services/`, `network/`, `uptime-kuma/`, `obsidian-vault-utils/`

## iTerm2 per-machine profiles

`scripts/iterm2-profiles/` — gives each machine an iTerm2 Dynamic Profile with
a distinct background color, so a glance at the terminal tells you which box
you're on. `setup.sh` symlinks the right one in based on `hostname -s`;
`bootstrap.sh` runs it automatically on a fresh machine. `profiles/example.json`
shows the shape — copy it per machine (not committed here, see `.gitignore`).
Details: `scripts/iterm2-profiles/README.md`.

## tmux

Config in `tmux/.tmux.conf` (TPM + tmux-resurrect/continuum for session
persistence across reboots). Per-machine session-layout scripts and a
remote-attach client aren't included — `tmux/README.md` documents the pattern
to build your own.

## Git workflow

If you fork this and work from multiple machines, before any `git add`:

```bash
git fetch && git pull --rebase
```

Then add, commit, push as normal.

## Obsidian vault tooling

`obsidian-vault-utils/` — daily-note workflow for one vault, plus index
generation and backup across every vault listed in `vaults.conf` (gitignored
— copy `vaults.conf.example` and edit).
