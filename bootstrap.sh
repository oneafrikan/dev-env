#!/usr/bin/env bash
# ─────────────────────────────────────────────
# bootstrap.sh — one-shot new machine setup
# Safe to run multiple times (idempotent)
#
# Platforms: macOS (darwin), Ubuntu (desktop or headless), Arch.
# Native package installs live in bootstrap/<platform>.sh; everything else
# is shared below.
#
#   bash bootstrap.sh              # do it
#   bash bootstrap.sh --dry-run    # print every action, change nothing
#
# Overrides (for testing / odd distros):
#   DEV_ENV_OS=darwin|ubuntu|arch
#   DEV_ENV_HEADLESS=0|1           # default: auto-detect on Linux
# ─────────────────────────────────────────────
set -euo pipefail

DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) DRY_RUN=1 ;;
    -h|--help) sed -n '3,15p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "  ✗ unknown argument: $arg (try --dry-run)" >&2; exit 2 ;;
  esac
done

# Repo root = the directory holding this script, so a clone anywhere (and a
# fork cloned to ~/.dev-env) wires itself, not some other clone. Falls back to
# ~/.dev-env if the script location can't be resolved (e.g. piped into bash).
_here="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || _here=""
if [[ -n "$_here" && -d "$_here/bootstrap" ]]; then
  DEV_ENV="$_here"
else
  DEV_ENV="$HOME/.dev-env"
fi
unset _here

log()  { echo "  [bootstrap] $1"; }
ok()   { echo "  ✓ $1"; }
warn() { echo "  ⚠ $1"; }
err()  { echo "  ✗ $1" >&2; }

# ── dry-run helpers (also used by bootstrap/*.sh) ──
is_dry() { [[ "$DRY_RUN" == 1 ]]; }
# run: execute a command, or just print it under --dry-run
run()  { if is_dry; then echo "  [dry-run] would: $*"; else "$@"; fi; }
# plan: print-only line for actions that can't go through run (redirects, $(...))
plan() { echo "  [dry-run] would: $*"; }
# did: success message that only makes sense if the action really ran
did()  { is_dry || ok "$1"; }
# pkgs_from: package names from a packages/*.txt file (strips comments)
pkgs_from() { sed 's/#.*//' "$1" | awk 'NF {print $1}'; }

# ── platform detection ────────────────────────
detect_os() {
  if [[ -n "${DEV_ENV_OS:-}" ]]; then
    case "$DEV_ENV_OS" in
      darwin|ubuntu|arch) echo "$DEV_ENV_OS"; return ;;
      *) err "DEV_ENV_OS must be darwin, ubuntu or arch (got '$DEV_ENV_OS')"; exit 2 ;;
    esac
  fi
  if [[ "$(uname -s)" == "Darwin" ]]; then echo darwin; return; fi
  local ids
  ids=" $( ( . /etc/os-release 2>/dev/null; echo "${ID:-} ${ID_LIKE:-}" ) ) "
  case "$ids" in
    *" arch "*)                 echo arch ;;
    *" ubuntu "*|*" debian "*)  echo ubuntu ;;
    *) err "Unsupported Linux ($ids). Set DEV_ENV_OS=ubuntu|arch to force one."; exit 2 ;;
  esac
}

# Linux is a desktop if any display/session variable is set. Caveat: an SSH
# session with X forwarding sets DISPLAY — override with DEV_ENV_HEADLESS.
detect_headless() {
  if [[ -n "${DEV_ENV_HEADLESS:-}" ]]; then
    case "$DEV_ENV_HEADLESS" in
      0|1) echo "$DEV_ENV_HEADLESS"; return ;;
      *) err "DEV_ENV_HEADLESS must be 0 or 1 (got '$DEV_ENV_HEADLESS')"; exit 2 ;;
    esac
  fi
  [[ "$PLATFORM" == darwin ]] && { echo 0; return; }
  if [[ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}${XDG_CURRENT_DESKTOP:-}" ]]; then echo 0; else echo 1; fi
}

PLATFORM="$(detect_os)"
HEADLESS="$(detect_headless)"

# Platform hooks — defaults are no-ops; bootstrap/<platform>.sh overrides them.
platform_packages()    { :; }   # native package installs
platform_ensure_mise() { :; }   # explicit, printed "get mise" step
platform_desktop()     { :; }   # GUI apps — only called when not headless
platform_post_links()   { :; }  # platform-specific dotfile links (after .gitconfig)
UV_SRC_HINT="the mise step"     # named in the error if uv is missing

# shellcheck source=/dev/null
source "$DEV_ENV/bootstrap/$PLATFORM.sh"

echo ""
echo "═══════════════════════════════════════════"
echo "  dev-env bootstrap"
echo "  $(date '+%Y-%m-%d %H:%M')"
if [[ "$PLATFORM" == darwin ]]; then
  echo "  platform: darwin"
else
  echo "  platform: $PLATFORM ($([[ "$HEADLESS" == 1 ]] && echo headless || echo desktop))"
fi
echo "  repo: $DEV_ENV"
is_dry && echo "  DRY RUN — nothing will be changed"
echo "═══════════════════════════════════════════"
echo ""

# ── 1-2. Native packages + mise ───────────────
platform_packages
platform_ensure_mise

# ── 2b. CLI tools from mise (Linux only) ──────
# macOS gets the same tools from the Brewfile, which stays its source of truth.
install_mise_tools() {
  log "Installing CLI tools via mise ($DEV_ENV/config/mise.toml)..."
  local src="$DEV_ENV/config/mise.toml"
  local conf_d="$HOME/.config/mise/conf.d"
  local dst="$conf_d/dev-env.toml"
  run mkdir -p "$conf_d"
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    ok "mise tool list already linked"
  elif [[ -e "$dst" || -L "$dst" ]]; then
    warn "$dst exists and is not this repo's list — leaving it alone"
  else
    run ln -s "$src" "$dst"
    did "mise tool list linked ($dst)"
  fi
  run mise trust "$src"
  # installs everything in the global mise config, including tools you
  # already declared in ~/.config/mise/config.toml — a no-op for those present
  run mise install
  # make the new tools visible to the rest of this run (uv, etc.)
  export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH"
  did "mise tools installed"
}
if [[ "$PLATFORM" != darwin ]]; then
  install_mise_tools
fi

# ── 2c. Desktop apps (not on headless) ────────
if [[ "$HEADLESS" == 0 ]]; then
  platform_desktop
elif [[ "$PLATFORM" != darwin ]]; then
  log "Headless — skipping desktop apps"
fi

# ── 3. TPM ────────────────────────────────────
log "Checking tmux plugin manager..."
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ ! -d "$TPM_DIR" ]]; then
  run git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
  did "TPM installed"
else
  ok "TPM already installed"
fi

# ── 4. uv + llm ──────────────────────────────
# try_install: run an install; treat failure as "already installed"
# (uv/llm exit non-zero when the tool is already present)
try_install() {
  local label="$1"; shift
  if is_dry; then plan "$*"; return 0; fi
  if "$@" 2>/dev/null; then ok "$label installed"; else ok "$label already installed"; fi
}

log "Installing llm via uv..."
if ! command -v uv &>/dev/null; then
  if is_dry; then
    warn "uv not on PATH yet — $UV_SRC_HINT would provide it"
  else
    err "uv not found — was $UV_SRC_HINT successful?"
    exit 1
  fi
fi

try_install llm uv tool install llm

# ── 5. llm plugins ───────────────────────────
log "Installing llm plugins..."
try_install llm-anthropic llm install llm-anthropic
try_install llm-gemini llm install llm-gemini

# ── 6. Companion tools ────────────────────────
log "Installing companion tools via uv..."
try_install files-to-prompt uv tool install files-to-prompt
try_install strip-tags uv tool install strip-tags
try_install ttok uv tool install ttok

# ── 7. fabric ────────────────────────────────
log "Checking fabric..."
if ! command -v go &>/dev/null; then
  warn "go not installed — skipping fabric. Install go first, then: go install github.com/danielmiessler/fabric@latest"
else
  if ! command -v fabric &>/dev/null; then
    log "Installing fabric..."
    run go install github.com/danielmiessler/fabric@latest
    did "fabric installed"
  else
    ok "fabric already installed"
  fi
fi

# ── 8. Symlink dotfiles ───────────────────────
log "Symlinking dotfiles..."

# .tmux.conf
TMUX_CONF="$HOME/.tmux.conf"
if [[ -L "$TMUX_CONF" ]]; then
  ok ".tmux.conf symlink already exists"
elif [[ -f "$TMUX_CONF" ]]; then
  warn ".tmux.conf exists as a real file — backing up to .tmux.conf.bak"
  run mv "$TMUX_CONF" "${TMUX_CONF}.bak"
  run ln -s "$DEV_ENV/tmux/.tmux.conf" "$TMUX_CONF"
  did ".tmux.conf symlinked (backup created)"
else
  run ln -s "$DEV_ENV/tmux/.tmux.conf" "$TMUX_CONF"
  did ".tmux.conf symlinked"
fi

# .gitconfig (template only — user must set name/email)
GITCONFIG="$HOME/.gitconfig"
if [[ ! -f "$GITCONFIG" ]]; then
  run cp "$DEV_ENV/git/.gitconfig" "$GITCONFIG"
  did ".gitconfig copied (edit it to set user.name and user.email)"
else
  ok ".gitconfig already exists — not overwriting"
fi

# The template sets core.editor = "cursor --wait". Don't change it — just say
# so if cursor isn't here, since `git commit` would otherwise fail confusingly.
GITCONFIG_SRC="$GITCONFIG"; [[ -f "$GITCONFIG" ]] || GITCONFIG_SRC="$DEV_ENV/git/.gitconfig"
if grep -Eq '^[[:space:]]*editor[[:space:]]*=[[:space:]]*cursor' "$GITCONFIG_SRC" 2>/dev/null \
   && ! command -v cursor &>/dev/null; then
  if is_dry && [[ "$PLATFORM" == darwin ]]; then
    ok "cursor will come from the Brewfile cask (git core.editor = cursor)"
  else
    warn "git core.editor is 'cursor --wait' but 'cursor' is not on PATH — install Cursor or run: git config --global core.editor '<your editor> --wait'"
  fi
fi

# platform-specific links (macOS: Hammerspoon, iTerm2)
platform_post_links

# ── 9. Wire shell functions into the shell rc ─
# macOS keeps .zshrc. On Linux write .zshrc only if the login shell is zsh,
# otherwise .bashrc (the shell files also source cleanly under bash).
if [[ "$PLATFORM" != darwin && "$(basename "${SHELL:-}")" != zsh ]]; then
  RC_FILE="$HOME/.bashrc"; RC_SHELL=bash
else
  RC_FILE="$HOME/.zshrc";  RC_SHELL=zsh
fi
log "Wiring shell functions into $(basename "$RC_FILE")..."
MARKER="# dev-env: managed block"

# The rc line points at whichever clone ran bootstrap. Under $HOME it is
# written as "$HOME/…" (so ~/.dev-env gives the classic "$HOME/.dev-env").
case "$DEV_ENV" in
  "$HOME"/*) DEV_ENV_RC='$HOME'"${DEV_ENV#"$HOME"}" ;;
  *)         DEV_ENV_RC="$DEV_ENV" ;;
esac

rc_block() {
  echo ""
  echo "$MARKER"
  echo "export DEV_ENV=\"$DEV_ENV_RC\""
  if [[ "$PLATFORM" != darwin ]]; then
    # tools installed by mise need activating in new shells; safe if already active
    echo "if command -v mise >/dev/null 2>&1; then eval \"\$(mise activate $RC_SHELL)\"; fi"
  fi
  echo 'source "$DEV_ENV/shell/functions.zsh"'
  echo 'source "$DEV_ENV/shell/aliases.zsh"'
  echo "# end dev-env"
}

if grep -q "$MARKER" "$RC_FILE" 2>/dev/null; then
  ok "$(basename "$RC_FILE") already wired"
  existing="$(grep -m1 '^export DEV_ENV=' "$RC_FILE" || true)"
  if [[ -n "$existing" && "$existing" != "export DEV_ENV=\"$DEV_ENV_RC\"" ]]; then
    warn "$(basename "$RC_FILE") points at a different clone ($existing) than this one (\"$DEV_ENV_RC\") — edit it if that's not intended"
  fi
elif is_dry; then
  plan "append to $RC_FILE:"
  rc_block | sed 's/^/                    | /'
else
  rc_block >> "$RC_FILE"
  ok "$(basename "$RC_FILE") wired — reload with: source ~/$(basename "$RC_FILE")"
fi

# ── 10. pyenv setup ───────────────────────────
# On Linux mise (already present) owns Python; the pyenv step is macOS-only.
log "Checking pyenv..."
PYTHON_VERSION_FILE="$DEV_ENV/python/.python-version"
if [[ "$PLATFORM" != darwin ]] && command -v mise &>/dev/null; then
  ok "mise present — skipping pyenv (Python comes from mise)"
elif [[ -f "$PYTHON_VERSION_FILE" ]]; then
  PYTHON_VERSION=$(cat "$PYTHON_VERSION_FILE")
  if command -v pyenv &>/dev/null; then
    if pyenv versions --bare | grep -q "^${PYTHON_VERSION}$"; then
      ok "Python $PYTHON_VERSION already installed via pyenv"
    else
      log "Installing Python $PYTHON_VERSION via pyenv..."
      run pyenv install "$PYTHON_VERSION"
      did "Python $PYTHON_VERSION installed"
    fi
  else
    warn "pyenv not found — skipping Python $PYTHON_VERSION install"
  fi
fi

# ── 11. chmod +x all scripts ──────────────────
log "Making all .sh files executable..."
run find "$DEV_ENV" -name "*.sh" -exec chmod +x {} \;
did "All scripts executable"

# ── 12. Validate contexts ─────────────────────
log "Running context validation..."
if [[ -x "$DEV_ENV/meta/validate-contexts.sh" ]]; then
  if is_dry; then
    plan "$DEV_ENV/meta/validate-contexts.sh"
  else
    "$DEV_ENV/meta/validate-contexts.sh" || warn "Some context checks failed — see above"
  fi
fi

# ── 13. Summary ───────────────────────────────
echo ""
echo "═══════════════════════════════════════════"
if is_dry; then
  echo "  Dry run complete — nothing was changed"
else
  echo "  Bootstrap complete"
fi
echo "═══════════════════════════════════════════"
echo ""
echo "Next steps:"
printf '  1. %-34s— activate shell functions\n' "source ~/$(basename "$RC_FILE")"
echo "  2. Check git/.gitconfig              — set user.name and user.email"
echo "  3. llm keys set anthropic            — set your Anthropic API key"
echo "  4. op signin                         — sign in to 1Password CLI"
echo "  5. tmux new-session then prefix+I    — install TPM plugins"
echo "  6. ctx example                       — test your first context"
echo ""
