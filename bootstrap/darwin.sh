# ─────────────────────────────────────────────
# bootstrap/darwin.sh — macOS package install
# Sourced by bootstrap.sh (not executed). Homebrew + the Brewfile (casks
# included) stay the macOS source of truth; mise and the CLI tools arrive
# through the Brewfile, so config/mise.toml is not used here.
# ─────────────────────────────────────────────
UV_SRC_HINT="brew bundle"

platform_packages() {
  # ── 1. Homebrew ─────────────────────────────
  log "Checking Homebrew..."
  if ! command -v brew &>/dev/null; then
    log "Installing Homebrew..."
    if is_dry; then
      plan '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    else
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
  else
    ok "Homebrew already installed ($(brew --version | head -1))"
  fi

  # ── 2. Brew bundle ──────────────────────────
  log "Running brew bundle..."
  run brew bundle --file="$DEV_ENV/Brewfile" --no-lock
  did "Brewfile applied"
}

platform_ensure_mise() {
  # mise is `brew "mise"` in the Brewfile, so it is already handled above.
  log "Ensuring mise..."
  ok "mise comes from the Brewfile (brew \"mise\")"
}

# Hammerspoon + iTerm2 (originally guarded by `uname -s == Darwin`; this file
# is only loaded on darwin, so the guard is implicit)
platform_post_links() {
  # Hammerspoon init.lua
  local HS_DIR="$HOME/.hammerspoon"
  local HS_INIT="$HS_DIR/init.lua"
  run mkdir -p "$HS_DIR"
  if [[ -L "$HS_INIT" ]]; then
    ok "Hammerspoon init.lua symlink already exists"
  elif [[ -f "$HS_INIT" ]]; then
    warn "Hammerspoon init.lua exists as real file — backing up"
    run mv "$HS_INIT" "${HS_INIT}.bak"
    run ln -s "$DEV_ENV/hammerspoon/init.lua" "$HS_INIT"
    did "Hammerspoon init.lua symlinked (backup created)"
  else
    run ln -s "$DEV_ENV/hammerspoon/init.lua" "$HS_INIT"
    did "Hammerspoon init.lua symlinked"
  fi

  # iTerm2 per-machine profile
  log "Setting up iTerm2 profile..."
  if run bash "$DEV_ENV/scripts/iterm2-profiles/setup.sh"; then
    did "iTerm2 profile linked"
  else
    warn "iTerm2 profile setup failed — see scripts/iterm2-profiles/README.md"
  fi
}
