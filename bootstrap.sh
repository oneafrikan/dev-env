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
#   bash bootstrap.sh --with-cursor  # Linux desktop: also install Cursor (opt-in)
#
# Overrides (for testing / odd distros):
#   DEV_ENV_OS=darwin|ubuntu|arch
#   DEV_ENV_HEADLESS=0|1           # default: auto-detect on Linux
#   DEV_ENV_WITH_CURSOR=1          # same as --with-cursor
# ─────────────────────────────────────────────
set -euo pipefail

DRY_RUN=0
WITH_CURSOR="${DEV_ENV_WITH_CURSOR:-0}"   # macOS gets Cursor from the Brewfile regardless
for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) DRY_RUN=1 ;;
    --with-cursor) WITH_CURSOR=1 ;;
    -h|--help) sed -n '3,17p' "${BASH_SOURCE[0]:-$0}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "  ✗ unknown argument: $arg (try --dry-run, --with-cursor)" >&2; exit 2 ;;
  esac
done

# Repo root = the directory holding this script, so a clone anywhere (and a
# fork cloned to ~/.dev-env) wires itself, not some other clone. Falls back to
# ~/.dev-env if the script location can't be resolved (e.g. piped into bash).
_src="${BASH_SOURCE[0]:-$0}"   # unset when piped (curl | bash); $0 is then just "bash"
_here=""
[[ -f "$_src" ]] && { _here="$(cd "$(dirname "$_src")" 2>/dev/null && pwd)" || _here=""; }
if [[ -n "$_here" && -d "$_here/bootstrap" ]]; then
  DEV_ENV="$_here"
elif [[ -d "$HOME/.dev-env/bootstrap" ]]; then
  DEV_ENV="$HOME/.dev-env"
  echo "  ⚠ can't locate this script on disk (piped into bash?) — using $DEV_ENV" >&2
else
  echo "  ✗ can't locate this script on disk (piped into bash?) and $HOME/.dev-env has no bootstrap/." >&2
  echo "    Piping isn't supported — clone first: git clone <repo-url> ~/.dev-env && bash ~/.dev-env/bootstrap.sh" >&2
  exit 1
fi
unset _src _here
export DEV_ENV   # children (meta/validate-contexts.sh, bootstrap/*.sh helpers) default to ~/.dev-env otherwise

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
# have_cursor: on PATH, or (dry-run) a platform hook just planned its install
have_cursor() { command -v cursor &>/dev/null || [[ "${CURSOR_PLANNED:-}" == 1 ]]; }

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
# Only tools whose binary is not already on PATH are installed (pacman, apt or
# a global mise entry may already provide it), at the versions pinned in
# config/mise.toml. Never a bare `mise install`: that would also process the
# user's global mise config. The chosen tools are written to a generated file we
# own under conf.d/, so ~/.config/mise/config.toml is never touched.
install_mise_tools() {
  log "Installing CLI tools via mise (pins: $DEV_ENV/config/mise.toml)..."
  local src="$DEV_ENV/config/mise.toml"
  local conf_d="$HOME/.config/mise/conf.d"
  local dst="$conf_d/dev-env.toml"
  local tool ver bin found pins="" args=() ours=0
  # An earlier run's generated file (not a symlink) lists the tools this
  # bootstrap installed; keep those pinned — their shims are on PATH now, so
  # a PATH check alone would wrongly drop them from the file.
  [[ -f "$dst" && ! -L "$dst" ]] && head -1 "$dst" | grep -q '^# Generated by dev-env bootstrap.sh' && ours=1
  while read -r tool ver; do
    bin="$tool"; [[ "$tool" == ripgrep ]] && bin=rg    # the one name != binary
    if [[ "$ours" == 1 ]] && grep -q "^$tool = " "$dst"; then
      echo "  INSTALL $tool@$ver (pinned by an earlier run; no-op if present)"
    elif found="$(command -v "$bin" 2>/dev/null)"; then
      echo "  SKIP    $tool (already on PATH: $found)"
      continue
    else
      echo "  INSTALL $tool@$ver"
    fi
    args+=("$tool@$ver"); pins+="$tool = \"$ver\""$'\n'
  done < <(sed -n 's/^\([A-Za-z0-9_:.\/-]*\) *= *"\([^"]*\)".*/\1 \2/p' "$src")
  if (( ${#args[@]} )); then
    run mise install "${args[@]}"    # explicit tool@version only
  else
    ok "nothing to install — every tool is already on PATH"
  fi
  # Write the file only after the install, so it never lists a missing tool.
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    run rm "$dst"                    # old bootstrap linked the whole repo list here
  elif [[ -L "$dst" ]]; then
    warn "$dst is a symlink — leaving it alone; installed tools are not pinned in mise config"
    return 0
  elif [[ -f "$dst" && "$ours" == 0 ]]; then
    warn "$dst is not a file this script generated (no header) — leaving it alone; installed tools are not pinned in mise config"
    return 0
  fi
  run mkdir -p "$conf_d"
  if is_dry; then
    plan "write $dst (regenerated each run):"
    printf '%s' "$pins" | sed 's/^/                    | /'
  else
    { echo "# Generated by dev-env bootstrap.sh on each run — do not edit."
      echo "# Pins the tools it installed via mise (versions: config/mise.toml in the repo)."
      echo "[tools]"
      printf '%s' "$pins"; } > "$dst"
  fi
  # make the new tools visible to the rest of this run (uv, etc.)
  export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH"
  did "mise tools installed and pinned ($dst)"
}
if [[ "$PLATFORM" != darwin ]]; then
  install_mise_tools
fi

# ── 2c. Desktop apps (not on headless) ────────
if [[ "$HEADLESS" == 0 ]]; then
  platform_desktop
elif [[ "$PLATFORM" != darwin ]]; then
  log "Headless — skipping desktop apps"
  [[ "$WITH_CURSOR" == 1 ]] && warn "--with-cursor ignored: headless"
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
TMUX_XDG="${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf"
if [[ -L "$TMUX_CONF" ]]; then
  ok ".tmux.conf symlink already exists"
elif [[ -e "$TMUX_XDG" ]]; then
  # tmux may read both files; which loads first (and wins) is unverified, so
  # don't layer ours underneath an existing XDG config.
  ok "$TMUX_XDG exists — not creating ~/.tmux.conf (it would layer under it; load order unverified)"
  echo "      to opt in: ln -s $DEV_ENV/tmux/.tmux.conf $TMUX_CONF"
elif [[ -f "$TMUX_CONF" ]]; then
  warn ".tmux.conf exists as a real file — backing up to .tmux.conf.bak"
  run mv "$TMUX_CONF" "${TMUX_CONF}.bak"
  run ln -s "$DEV_ENV/tmux/.tmux.conf" "$TMUX_CONF"
  did ".tmux.conf symlinked (backup created)"
else
  run ln -s "$DEV_ENV/tmux/.tmux.conf" "$TMUX_CONF"
  did ".tmux.conf symlinked"
fi

# .gitconfig (template only — user must set name/email). Skip if ANY global
# git config exists (~/.gitconfig, XDG, or an identity git already resolves):
# a template ~/.gitconfig would override an XDG config's name/email/editor.
GITCONFIG="$HOME/.gitconfig"
GITCONFIG_XDG="${XDG_CONFIG_HOME:-$HOME/.config}/git/config"
if [[ -f "$GITCONFIG" || -f "$GITCONFIG_XDG" \
      || -n "$(git config --global --get user.name 2>/dev/null || true)" \
      || -n "$(git config --global --get user.email 2>/dev/null || true)" ]]; then
  ok "global git config already exists — not copying the template"
  _gitcfg=(--global)
  _tpl_copied=0
else
  run cp "$DEV_ENV/git/.gitconfig" "$GITCONFIG"
  did ".gitconfig copied (edit it to set user.name and user.email)"
  _gitcfg=(--file "$DEV_ENV/git/.gitconfig")   # what the copy will contain
  _tpl_copied=1
  # The template sets core.editor = "cursor --wait". On Linux Cursor is opt-in
  # (--with-cursor), so without it fall back to $EDITOR — in the file we just
  # created only; an existing git config is never edited. git runs the value
  # through sh, so ${EDITOR:-vi} expands at commit time.
  if [[ "$PLATFORM" != darwin ]] && ! have_cursor; then
    run git config --file "$GITCONFIG" core.editor '${EDITOR:-vi}'
    did "git core.editor set to \${EDITOR:-vi} (Cursor not installed; --with-cursor to install it)"
    _gitcfg=(--file "$GITCONFIG")
  fi
fi

# An existing global config may still say `cursor --wait` — don't change it,
# just say so if cursor isn't here, since `git commit` would fail confusingly.
if [[ "$(git config "${_gitcfg[@]}" --get core.editor 2>/dev/null || true)" == cursor* ]] \
   && ! have_cursor; then
  if is_dry && [[ "$PLATFORM" == darwin ]]; then
    ok "cursor will come from the Brewfile cask (git core.editor = cursor)"
  else
    warn "git core.editor is 'cursor --wait' but 'cursor' is not on PATH — install Cursor (--with-cursor on Linux desktop) or run: git config --global core.editor '<your editor> --wait'"
  fi
fi

# platform-specific links (macOS: Hammerspoon, iTerm2)
platform_post_links

# ── 9. Wire shell functions into the shell rc ─
# macOS keeps .zshrc. On Linux write .zshrc only if the login shell is zsh,
# otherwise .bashrc (functions.zsh also sources cleanly under bash).
if [[ "$PLATFORM" != darwin && "$(basename "${SHELL:-}")" != zsh ]]; then
  RC_FILE="$HOME/.bashrc"
else
  RC_FILE="$HOME/.zshrc"
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
    # Linux: shims only if not already on PATH; no `mise activate` (an existing
    # setup may have one) and no aliases.zsh (it would override the distro's
    # own ls/grep/cat/... aliases).
    echo 'case ":$PATH:" in *":$HOME/.local/share/mise/shims:"*) ;; *) export PATH="$HOME/.local/share/mise/shims:$PATH" ;; esac'
    echo 'source "$DEV_ENV/shell/functions.zsh"'
  else
    echo 'source "$DEV_ENV/shell/functions.zsh"'
    echo 'source "$DEV_ENV/shell/aliases.zsh"'
  fi
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
n=0; step() { n=$((n+1)); printf '  %d. %s\n' "$n" "$1"; }
step "$(printf '%-34s— activate shell functions' "source ~/$(basename "$RC_FILE")")"
# only when the template was copied — otherwise there is no file to edit
[[ "$_tpl_copied" == 1 ]] && step "Check git/.gitconfig              — set user.name and user.email"
step "llm keys set anthropic            — set your Anthropic API key"
step "op signin                         — sign in to 1Password CLI"
step "tmux new-session then prefix+I    — install TPM plugins"
step "ctx example                       — test your first context"
echo ""
