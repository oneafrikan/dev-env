#!/usr/bin/env bash
# ─────────────────────────────────────────────
# bootstrap.sh — one-shot new machine setup
# Safe to run multiple times (idempotent)
# ─────────────────────────────────────────────
set -euo pipefail

DEV_ENV="${DEV_ENV:-$HOME/.dev-env}"

log()  { echo "  [bootstrap] $1"; }
ok()   { echo "  ✓ $1"; }
warn() { echo "  ⚠ $1"; }
err()  { echo "  ✗ $1" >&2; }

echo ""
echo "═══════════════════════════════════════════"
echo "  dev-env bootstrap"
echo "  $(date '+%Y-%m-%d %H:%M')"
echo "═══════════════════════════════════════════"
echo ""

# ── 1. Homebrew ───────────────────────────────
log "Checking Homebrew..."
if ! command -v brew &>/dev/null; then
  log "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  ok "Homebrew already installed ($(brew --version | head -1))"
fi

# ── 2. Brew bundle ────────────────────────────
log "Running brew bundle..."
brew bundle --file="$DEV_ENV/Brewfile" --no-lock
ok "Brewfile applied"

# ── 3. TPM ────────────────────────────────────
log "Checking tmux plugin manager..."
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ ! -d "$TPM_DIR" ]]; then
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
  ok "TPM installed"
else
  ok "TPM already installed"
fi

# ── 4. uv + llm ──────────────────────────────
log "Installing llm via uv..."
if ! command -v uv &>/dev/null; then
  err "uv not found — was brew bundle successful?"
  exit 1
fi

uv tool install llm 2>/dev/null && ok "llm installed" || ok "llm already installed"

# ── 5. llm plugins ───────────────────────────
log "Installing llm plugins..."
llm install llm-anthropic 2>/dev/null && ok "llm-anthropic installed" || ok "llm-anthropic already installed"
llm install llm-gemini 2>/dev/null && ok "llm-gemini installed" || ok "llm-gemini already installed"

# ── 6. Companion tools ────────────────────────
log "Installing companion tools via uv..."
uv tool install files-to-prompt 2>/dev/null && ok "files-to-prompt installed" || ok "files-to-prompt already installed"
uv tool install strip-tags 2>/dev/null && ok "strip-tags installed" || ok "strip-tags already installed"
uv tool install ttok 2>/dev/null && ok "ttok installed" || ok "ttok already installed"

# ── 7. fabric ────────────────────────────────
log "Checking fabric..."
if ! command -v go &>/dev/null; then
  warn "go not installed — skipping fabric. Install go first, then: go install github.com/danielmiessler/fabric@latest"
else
  if ! command -v fabric &>/dev/null; then
    log "Installing fabric..."
    go install github.com/danielmiessler/fabric@latest
    ok "fabric installed"
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
  mv "$TMUX_CONF" "${TMUX_CONF}.bak"
  ln -s "$DEV_ENV/tmux/.tmux.conf" "$TMUX_CONF"
  ok ".tmux.conf symlinked (backup created)"
else
  ln -s "$DEV_ENV/tmux/.tmux.conf" "$TMUX_CONF"
  ok ".tmux.conf symlinked"
fi

# .gitconfig (template only — user must set name/email)
GITCONFIG="$HOME/.gitconfig"
if [[ ! -f "$GITCONFIG" ]]; then
  cp "$DEV_ENV/git/.gitconfig" "$GITCONFIG"
  ok ".gitconfig copied (edit it to set user.name and user.email)"
else
  ok ".gitconfig already exists — not overwriting"
fi

# Hammerspoon init.lua (macOS only)
if [[ "$(uname -s)" == "Darwin" ]]; then
  HS_DIR="$HOME/.hammerspoon"
  HS_INIT="$HS_DIR/init.lua"
  mkdir -p "$HS_DIR"
  if [[ -L "$HS_INIT" ]]; then
    ok "Hammerspoon init.lua symlink already exists"
  elif [[ -f "$HS_INIT" ]]; then
    warn "Hammerspoon init.lua exists as real file — backing up"
    mv "$HS_INIT" "${HS_INIT}.bak"
    ln -s "$DEV_ENV/hammerspoon/init.lua" "$HS_INIT"
    ok "Hammerspoon init.lua symlinked (backup created)"
  else
    ln -s "$DEV_ENV/hammerspoon/init.lua" "$HS_INIT"
    ok "Hammerspoon init.lua symlinked"
  fi
fi

# iTerm2 per-machine profile (macOS only)
if [[ "$(uname -s)" == "Darwin" ]]; then
  log "Setting up iTerm2 profile..."
  bash "$DEV_ENV/scripts/iterm2-profiles/setup.sh" && ok "iTerm2 profile linked" || warn "iTerm2 profile setup failed — see scripts/iterm2-profiles/README.md"
fi

# ── 9. Wire shell functions into .zshrc ───────
log "Wiring shell functions into .zshrc..."
ZSHRC="$HOME/.zshrc"
MARKER="# dev-env: managed block"

if grep -q "$MARKER" "$ZSHRC" 2>/dev/null; then
  ok ".zshrc already wired"
else
  cat >> "$ZSHRC" << ZSHBLOCK

$MARKER
export DEV_ENV="\$HOME/.dev-env"
source "\$DEV_ENV/shell/functions.zsh"
source "\$DEV_ENV/shell/aliases.zsh"
# end dev-env
ZSHBLOCK
  ok ".zshrc wired — reload with: source ~/.zshrc"
fi

# ── 10. pyenv setup ───────────────────────────
log "Checking pyenv..."
PYTHON_VERSION_FILE="$DEV_ENV/python/.python-version"
if [[ -f "$PYTHON_VERSION_FILE" ]]; then
  PYTHON_VERSION=$(cat "$PYTHON_VERSION_FILE")
  if command -v pyenv &>/dev/null; then
    if pyenv versions --bare | grep -q "^${PYTHON_VERSION}$"; then
      ok "Python $PYTHON_VERSION already installed via pyenv"
    else
      log "Installing Python $PYTHON_VERSION via pyenv..."
      pyenv install "$PYTHON_VERSION"
      ok "Python $PYTHON_VERSION installed"
    fi
  else
    warn "pyenv not found — skipping Python $PYTHON_VERSION install"
  fi
fi

# ── 11. chmod +x all scripts ──────────────────
log "Making all .sh files executable..."
find "$DEV_ENV" -name "*.sh" -exec chmod +x {} \;
ok "All scripts executable"

# ── 12. Validate contexts ─────────────────────
log "Running context validation..."
if [[ -x "$DEV_ENV/meta/validate-contexts.sh" ]]; then
  "$DEV_ENV/meta/validate-contexts.sh" || warn "Some context checks failed — see above"
fi

# ── 13. Summary ───────────────────────────────
echo ""
echo "═══════════════════════════════════════════"
echo "  Bootstrap complete"
echo "═══════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "  1. source ~/.zshrc                   — activate shell functions"
echo "  2. Check git/.gitconfig              — set user.name and user.email"
echo "  3. llm keys set anthropic            — set your Anthropic API key"
echo "  4. op signin                         — sign in to 1Password CLI"
echo "  5. tmux new-session then prefix+I    — install TPM plugins"
echo "  6. ctx example                       — test your first context"
echo ""
