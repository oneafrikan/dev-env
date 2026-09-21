# Portability: how the cross-OS setup works

One entry point, `bootstrap.sh`, sets up macOS, Ubuntu (desktop or headless) and
Arch. Platform-specific package installs live in `bootstrap/<platform>.sh`;
everything else is shared. Branch test procedure: [TESTING-PORTABLE-ARCH.md](TESTING-PORTABLE-ARCH.md).
Contributor rules: [Portability section of CLAUDE.md](../CLAUDE.md#portability-macos--ubuntu--arch).

Status words used in these docs: **dry-run verified** = `--dry-run` output was
read and matched the code; **untested** = never run on that OS. Nothing has run
for real on macOS or Ubuntu yet.

| Platform | Status |
|---|---|
| Arch | dry-run verified (on Arch); real run being done by the owner first |
| Ubuntu desktop / headless | dry-run verified only via forced `DEV_ENV_OS=ubuntu` on Arch; **untested** on Ubuntu |
| macOS | dry-run verified only via forced `DEV_ENV_OS=darwin` on Linux; **untested** on macOS, bash 3.2 and zsh |

## 1. Platform detection

`bootstrap.sh` decides the platform, then whether it is headless, then sources
`bootstrap/<platform>.sh`. The result is printed in the banner
(`platform: ubuntu (headless)`).

| Step | Rule |
|---|---|
| OS | `DEV_ENV_OS` if set (`darwin`, `ubuntu`, `arch`; anything else exits 2). Else `uname -s` = `Darwin` gives `darwin`. Else `/etc/os-release` `ID` + `ID_LIKE`: contains `arch` gives `arch`; contains `ubuntu` or `debian` gives `ubuntu` (so Debian and Mint take the apt path); anything else exits 2 "Unsupported Linux". |
| Headless | `DEV_ENV_HEADLESS` if set (`0` or `1`; else exit 2). macOS is always desktop. Linux is desktop if any of `WAYLAND_DISPLAY`, `DISPLAY`, `XDG_CURRENT_DESKTOP` is non-empty, else headless. |
| SSH caveat | SSH with X forwarding sets `DISPLAY`, so a headless server can be detected as desktop. Force it: `DEV_ENV_HEADLESS=1`. |

Detection logic was exercised with sample `ID`/`ID_LIKE` strings and on Arch;
the `Darwin` and real Ubuntu paths are read, not run.

### Flags and environment

| Name | Effect |
|---|---|
| `--dry-run`, `-n` | Print every action as `[dry-run] would: ...`; change nothing. Read-only probes still run (`command -v`, `git config --get`, `brew --version`, `/etc/os-release`). |
| `--with-cursor` or `DEV_ENV_WITH_CURSOR=1` | Linux desktop only: also install Cursor. Arch: adds `cursor-bin` to the `yay` call. Ubuntu: only prints a warning (vendor .deb, cannot be automated). Headless: ignored with a warning. macOS: no effect (the Brewfile installs the cursor cask regardless). |
| `DEV_ENV_OS`, `DEV_ENV_HEADLESS` | Overrides above. `DEV_ENV_OS=darwin` works on Linux for previewing the macOS plan. |
| `-h`, `--help` | Print the header comment and exit 0. |
| anything else | Exit 2 "unknown argument". |

## 2. The four platform hooks

`bootstrap.sh` defines no-op defaults; `bootstrap/<platform>.sh` (sourced, never
executed) overrides them.

| Hook | Called | Arch | Ubuntu | macOS |
|---|---|---|---|---|
| `platform_packages` | first | `sudo pacman -S --needed --noconfirm` from `packages/pacman.txt` | `sudo apt-get update` + `apt-get install -y` from `packages/apt.txt` | install Homebrew if missing, `brew bundle --file=Brewfile --no-lock` |
| `platform_ensure_mise` | after packages | `pacman -S mise` if missing | add mise's apt repo, `apt-get install mise` if missing | no-op message (mise is in the Brewfile) |
| `platform_desktop` | only when not headless, after the mise tools | `yay -S --needed` from `packages/aur.txt` (+`cursor-bin` with the flag); skipped with a warning if `yay` is missing | `sudo snap install obsidian --classic` (warning if no snap) | not defined (casks come from the Brewfile) |
| `platform_post_links` | after the `.gitconfig` step | not defined | not defined | link `~/.hammerspoon/init.lua` (backs up a real file to `.bak`); run `scripts/iterm2-profiles/setup.sh` |

Helpers available to platform files: `run` (execute, or print under dry-run),
`plan` (print-only, for redirects and `$(...)`), `did` (success message that is
silent under dry-run), `is_dry`, `pkgs_from <file>` (package names, comments
stripped), `log`/`ok`/`warn`/`err`. Variables: `PLATFORM`, `HEADLESS`,
`WITH_CURSOR`, `DEV_ENV`, `UV_SRC_HINT` (name of the step that provides `uv`, used
in the error if it is missing), `CURSOR_PLANNED=1` (set by a hook that just planned a
Cursor install so the dry-run git-editor step knows).

## 3. What each platform installs, and from where

| | macOS | Ubuntu | Arch |
|---|---|---|---|
| Native packages | `Brewfile` (formulae + casks, including `mise`, `pyenv`, `nvm`, `cursor`, `hammerspoon`, `iterm2`, `obsidian`) | `packages/apt.txt`: ca-certificates, curl, wget, gpg, git, tmux, htop, tree, httpie, csvkit | `packages/pacman.txt`: git, tmux, wget, htop, tree, httpie, csvkit |
| mise itself | Brewfile | mise's apt repo (`/etc/apt/sources.list.d/mise.list`) | `pacman -S mise` |
| CLI tools (eza, bat, rg, fd, fzf, jq, gh, uv, just, ...) | Brewfile | mise, pinned (section 4) | mise, pinned (section 4) |
| Desktop apps | Brewfile casks | snap: Obsidian | `yay`: `packages/aur.txt` (Obsidian) |
| Cursor | Brewfile cask (always) | not automated; `--with-cursor` prints a hint | `--with-cursor` adds `cursor-bin` |
| Shell files | zsh, `functions.zsh` + `aliases.zsh` | bash, `functions.zsh` only | bash, `functions.zsh` only |
| Python | pyenv step (`python/.python-version`) | skipped when mise is present | skipped when mise is present |

Shared on every platform, in order: tmux plugin manager clone to
`~/.tmux/plugins/tpm`; `uv tool install` of `llm`, `files-to-prompt`,
`strip-tags`, `ttok`, plus `llm install llm-anthropic llm-gemini`; `fabric` via
`go install` only if `go` is already on PATH (no package list provides `go`, so it
is normally skipped with a warning); tmux and git links (section 7); shell rc
block (section 5); `chmod +x` on every `*.sh` in the clone; `meta/validate-contexts.sh`.

`zsh` is deliberately not in `apt.txt` / `pacman.txt`: on Linux the shell files
are sourced by bash.

## 4. The mise tool list (Linux only)

`config/mise.toml` is the single pinned list for Ubuntu and Arch. macOS never
reads it; the `Brewfile` stays the macOS source of truth. Keep the two in step by
hand.

Rules `install_mise_tools` follows:

| Rule | Detail |
|---|---|
| Pinned | Each tool is `name = "x.y.z"` under `[tools]`, one per line (the script parses that shape). |
| Only if missing | A tool is installed only if its binary is not already on PATH (`command -v`; the one name/binary mismatch is `ripgrep` -> `rg`). Found: prints `SKIP <tool> (already on PATH: ...)`. |
| Earlier runs stay pinned | If a previous run generated `dev-env.toml` and it lists the tool, the tool stays listed (its shim is on PATH by now). Printed as `INSTALL <tool>@<ver> (pinned by an earlier run; no-op if present)`. |
| Explicit install | `mise install tool@ver tool@ver ...` for the chosen tools only. **Never a bare `mise install`** (it would process the user's global mise config), no `mise use`, no `mise trust` (the repo file is never linked into mise). |
| Generated file | After the install, `~/.config/mise/conf.d/dev-env.toml` is rewritten on every run: header comment, `[tools]`, the chosen pins. It never lists a tool that failed to install. `mise ls` and `mise config ls` pick it up (checked). |
| User config untouched | `~/.config/mise/config.toml` is never read or written by the script. |
| Symlink at that path | Symlink to the repo's `config/mise.toml` (left by an earlier bootstrap): removed and replaced by the generated file. Any other symlink: left alone, warning, tools are installed but not pinned. |
| Regular file at that path | Overwritten only if its first line is the header the script writes (`# Generated by dev-env bootstrap.sh`). Any other regular file: left alone, warning, tools are installed but not pinned (same as a foreign symlink). Don't hand-edit the generated file. |
| Shims | `~/.local/share/mise/shims` and `~/.local/bin` are prepended to PATH for the rest of the run so `uv` is found. |

Dry-run shows the `mise install` line and the exact file body.

## 5. The shell rc block

The block is appended once, between `# dev-env: managed block` and `# end dev-env`.

| Platform | File | Block contents |
|---|---|---|
| macOS | `~/.zshrc` | `export DEV_ENV=...`; `source functions.zsh`; `source aliases.zsh`. Same content as the original macOS bootstrap on `main`. |
| Linux, login shell not zsh (or `SHELL` unset) | `~/.bashrc` | `export DEV_ENV=...`; a `case` that prepends `~/.local/share/mise/shims` to PATH only if absent; `source functions.zsh`. |
| Linux, login shell zsh | `~/.zshrc` | same Linux block as above |

On Linux the block deliberately has **no aliases** (`aliases.zsh` would replace the
distro's `ls`/`grep`/`cat`/`find`) and **no `mise activate`** (an existing setup
may already have one). `ctx`, the tmux/venv/LLM helper functions and completions
(zsh only) come from `functions.zsh`, which sources cleanly under bash.

Linux prerequisites: update the system first (Arch: `sudo pacman -Syu`; the bootstrap runs `pacman -S` without `-y`, so a stale package database can 404 before the mise step), and run `bootstrap.sh` from the clone you want active, because the block exports that clone's path as `DEV_ENV`.

Existing block: if the marker is already in the file the script prints
`already wired` and **does not rewrite it**, even if it was written by an older
bootstrap. Older Linux blocks (earlier commits on this branch) contain
`eval "$(mise activate ...)"` and `source .../aliases.zsh`; find them with
`grep -n 'mise activate\|aliases.zsh' ~/.bashrc`. To move to the new block,
remove the old one (see Rollback in the test guide) and re-run. If the existing
block's `export DEV_ENV=` differs from this clone, the script warns
`points at a different clone`.

A Debian/Ubuntu `~/.bashrc` returns early for non-interactive shells; the block is
appended at the end, so it only takes effect in interactive shells.

## 6. How `DEV_ENV` is derived

| Where | Rule |
|---|---|
| `bootstrap.sh` | The directory holding the script (`BASH_SOURCE`), if it has a `bootstrap/` dir. If the script can't be located (piped into bash) and `~/.dev-env/bootstrap/` exists: use `~/.dev-env` with a warning. Otherwise exit 1. Piped `curl \| bash` is unsupported. |
| rc block | Written as `export DEV_ENV="$HOME/<rest>"` when the clone is under `$HOME` (so `~/.dev-env` gives the classic `$HOME/.dev-env`), else the absolute path. |
| `shell/functions.zsh` | Overwrites `DEV_ENV` with the parent of its own `shell/` directory: `BASH_SOURCE[0]` under bash, `${(%):-%x}` under zsh (via `eval`, because `(%)` is a bash syntax error). If that fails or `shell/functions.zsh` isn't there, falls back to `$HOME/.dev-env`. The fallback is silent, so on a clone that is not at `~/.dev-env` always check `echo $DEV_ENV`. |
| Symlinks | Sourcing through a symlinked **directory** gives the symlinked path; sourcing through a symlinked **file** falls back to `~/.dev-env`. |
| The zsh branch | **Untested**: it has never run under zsh. |
| Exported to children | `bootstrap.sh` exports `DEV_ENV` (the derived repo root) right after computing it, so `meta/validate-contexts.sh` (run at the end, which defaults to `$HOME/.dev-env`) checks this clone. Before the export, on a clone not at `~/.dev-env` it looked in the wrong place and reported a failed check. |

## 7. git config and tmux.conf skip rules

Both are XDG-aware (`$XDG_CONFIG_HOME`, default `~/.config`) and apply on every
platform including macOS.

| Item | Action |
|---|---|
| `~/.tmux.conf` | Already a symlink: keep. Else `$XDG_CONFIG_HOME/tmux/tmux.conf` exists: **do not create** `~/.tmux.conf` (load order between the two files is unverified); prints the `ln -s` to opt in. Else a real file: move to `.tmux.conf.bak`, then link. Else: link to `tmux/.tmux.conf`. |
| global git config | Skip the template if `~/.gitconfig` exists, or `$XDG_CONFIG_HOME/git/config` exists, or `git config --global` already resolves a `user.name` or `user.email`. Otherwise copy `git/.gitconfig` to `~/.gitconfig` (placeholders `Your Name` / `you@example.com`; edit them). |
| `core.editor` | The template says `cursor --wait`. Linux without Cursor (no `cursor` on PATH and none planned): in the newly copied file only, set it to `${EDITOR:-vi}`. An existing git config is never edited; if it says `cursor` and `cursor` is missing, a warning says so. |

## 8. Extending

**Add a CLI tool** (available everywhere)
1. Check the mise name: `mise registry | grep -i <name>`; get a version: `mise latest <name>`.
2. Add `name = "x.y.z"` to `config/mise.toml` (one line, quoted version). If the binary name differs from the tool name, teach `install_mise_tools` (today only `ripgrep` -> `rg`).
3. Add it to the `Brewfile` (macOS does not read `config/mise.toml`).
4. If mise cannot provide it, put it in `packages/apt.txt` and `packages/pacman.txt` with a comment saying why.
5. `bash bootstrap.sh --dry-run` on each platform you can reach (`DEV_ENV_OS=... ` for the others).

**Add a native package or desktop app**: one line per package in `packages/{apt,pacman,aur}.txt` (`#` comments allowed, one name per line) and the `Brewfile`. Desktop-only apps go in `aur.txt` or the `platform_desktop` hook, never in the always-run lists.

**Add a platform**
1. `bootstrap/<name>.sh`: override the four hooks; route every mutating command through `run` or `plan`; no bash 4+ features (macOS ships bash 3.2).
2. `bootstrap.sh`: add the id to `detect_os` and to the `DEV_ENV_OS` validation and help text.
3. Add `packages/<name>.txt` if it has native packages; list each entry with a reason.
4. Update `bootstrap/CLAUDE.md`, this file, and the test guide.
5. Dry-run it (`DEV_ENV_OS=<name>`) before any real run.

If you also keep a private overlay, apply the same changes there.

## 9. Rules for contributors

The portability rules (`lib/platform.sh` wrappers, `set -u` hygiene, shell files
must work under bash and zsh, mac-only scripts guarded by `uname -s`, no
Homebrew-only hints, per-machine config in gitignored files) live in one place:
[CLAUDE.md, Portability section](../CLAUDE.md#portability-macos--ubuntu--arch).
Follow those; they are not repeated here.
