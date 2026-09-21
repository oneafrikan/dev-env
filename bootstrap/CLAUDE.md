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
  `bootstrap.sh --dry-run` prints it instead of executing it. Other helpers from
  `bootstrap.sh`: `did` (success message, silent under dry-run), `is_dry`,
  `pkgs_from <file>` (package names, comments stripped), `log`/`ok`/`warn`/`err`.
- Variables a platform file may use: `PLATFORM`, `HEADLESS`, `WITH_CURSOR`
  (`--with-cursor` / `DEV_ENV_WITH_CURSOR=1`), `DEV_ENV` (exported). It may set `UV_SRC_HINT`
  (names the step that provides `uv` in the error) and `CURSOR_PLANNED=1` (after
  planning a Cursor install, so the dry-run git-editor step knows).
- macOS installs from the `Brewfile` (casks included; `config/mise.toml` is not
  read). Linux gets CLI tools from mise: pinned versions from `config/mise.toml`,
  only tools whose binary is not already on `PATH`, installed as explicit
  `tool@version` (never a bare `mise install`) and recorded in the generated
  `~/.config/mise/conf.d/dev-env.toml` (overwritten only if it has the generated header);
  the user's mise config is never touched.
  Only what mise can't provide comes from `packages/{apt,pacman,aur}.txt`, each
  entry commented with why. That logic lives in `bootstrap.sh`, not here.
- Cursor is opt-in on Linux (`--with-cursor`): not in `aur.txt`; Ubuntu can only
  print a pointer. macOS still gets the `cursor` cask from the `Brewfile`.
- No bash 4+ features (`mapfile`, associative arrays): macOS ships bash 3.2.
- Design, test guide: `docs/PORTABILITY.md`, `docs/TESTING-PORTABLE-ARCH.md`.

## Scripts

| Name       | Status      | Description                                   |
|------------|-------------|-----------------------------------------------|
| darwin.sh  | implemented | Homebrew + Brewfile, Hammerspoon, iTerm2       |
| ubuntu.sh  | implemented | apt packages, mise apt repo, snap Obsidian     |
| arch.sh    | implemented | pacman packages, mise, yay desktop apps (+`cursor-bin` with `--with-cursor`) |

## Secrets

None.
