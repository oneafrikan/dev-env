# ─────────────────────────────────────────────
# bootstrap/ubuntu.sh — Ubuntu package install (desktop or headless)
# Sourced by bootstrap.sh (not executed). Only what mise can't provide is
# installed natively (packages/apt.txt); the CLI tools come from mise via
# config/mise.toml. mise itself comes from its official signed apt repo.
# ─────────────────────────────────────────────

platform_packages() {
  log "Installing apt packages (packages/apt.txt)..."
  local pkgs
  pkgs="$(pkgs_from "$DEV_ENV/packages/apt.txt" | tr '\n' ' ')"
  run sudo apt-get update
  # apt-get install of an installed package is a no-op, so re-runs are safe
  # shellcheck disable=SC2086
  run sudo apt-get install -y $pkgs
  did "apt packages installed"
}

platform_ensure_mise() {
  log "Ensuring mise..."
  if command -v mise &>/dev/null; then
    ok "mise already installed ($(mise --version 2>/dev/null | head -1))"
    return 0
  fi
  # Official apt repo (https://mise.jdx.dev/installing-mise.html#apt) —
  # signed, and upgraded by apt afterwards; preferred over curl|sh.
  local key=/etc/apt/keyrings/mise-archive-keyring.gpg
  local list=/etc/apt/sources.list.d/mise.list
  if [[ ! -f "$list" ]]; then
    run sudo install -dm 755 /etc/apt/keyrings
    run bash -c "wget -qO - https://mise.jdx.dev/gpg-key.pub | gpg --dearmor | sudo tee $key >/dev/null"
    run bash -c "echo \"deb [signed-by=$key arch=\$(dpkg --print-architecture)] https://mise.jdx.dev/deb stable main\" | sudo tee $list >/dev/null"
  fi
  run sudo apt-get update
  run sudo apt-get install -y mise
  did "mise installed"
}

# Desktop only — bootstrap.sh skips this when headless.
platform_desktop() {
  log "Installing desktop apps..."
  if command -v snap &>/dev/null; then
    run sudo snap install obsidian --classic
    did "Obsidian installed"
  else
    warn "snap not found — install Obsidian manually (no apt package)"
  fi
  # Cursor has no apt package or snap; the git template needs it (see the
  # editor warning further down). Not automated: it's a vendor .deb download.
  warn "Cursor is not installed automatically — get the .deb from cursor.com if you want it"
}
