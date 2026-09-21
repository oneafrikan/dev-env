# CLAUDE.md — shell/

## Purpose

zsh functions and aliases. bootstrap.sh wires them into the shell rc: macOS writes ~/.zshrc
(sources functions.zsh and aliases.zsh); Linux writes ~/.zshrc if the login shell is zsh, else
~/.bashrc, and sources only functions.zsh (no aliases, which would override the distro's own).

## Conventions

- Source order: functions.zsh first (sets DEV_ENV from its own location: the parent of `shell/`), then aliases.zsh (macOS only)
- functions.zsh must be sourced, not executed
- `ctx` has zsh tab completion, dynamically discovered from `contexts/*.sh`

## Dependencies

- `eza`, `bat`, `ripgrep`, `fd`, `fzf`, `btop` — for aliased commands
- `uv` — for mkvenv
- `supacode` — for `_sc_wt` / `sc_open` helpers (optional — see functions.zsh)
- `tmux` — for `tls`/`ta`/`tk`

## Scripts

| Name          | Status      | Description                                              |
|---------------|-------------|----------------------------------------------------------|
| functions.zsh | implemented | ctx, supacode helpers, tmux helpers, venv, LLM shortcuts |
| aliases.zsh   | implemented | CLI replacements, git, Python, context nav               |

## supacode helpers

- `_sc_wt <path>` — URL-encodes a path into a supacode worktree ID
- `sc_open <path> [cmd...]` — opens repo in supacode; creates named tabs on first open (idempotent)

## Secrets

None.
