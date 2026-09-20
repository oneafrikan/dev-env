# CLAUDE.md — bootstrap/

## Purpose

Per-platform package installation for `bootstrap.sh` (the one entry point).
`bootstrap.sh` detects the platform, sources `bootstrap/<platform>.sh`, then
runs the shared steps (TPM, uv tools, dotfile links, shell rc, checks).

## Conventions

- Files are sourced, not executed. They override the hooks `bootstrap.sh`
  defines: `platform_packages`, `platform_ensure_mise`, `platform_desktop`
  (only called when not headless), `platform_post_links`.
- Every mutating command goes through `run` (or `plan` when it can't) so
  `bootstrap.sh --dry-run` prints it instead of executing it.
- macOS installs from the `Brewfile` (casks included). Linux gets CLI tools
  from mise (`config/mise.toml`) and only what mise can't provide from
  `packages/{apt,pacman,aur}.txt` — each entry commented with why.
- No bash 4+ features (`mapfile`, associative arrays): macOS ships bash 3.2.

## Scripts

| Name       | Status      | Description                                   |
|------------|-------------|-----------------------------------------------|
| darwin.sh  | implemented | Homebrew + Brewfile, Hammerspoon, iTerm2       |
| ubuntu.sh  | implemented | apt packages, mise apt repo, snap Obsidian     |
| arch.sh    | implemented | pacman packages, mise, yay desktop apps        |

## Secrets

None.
