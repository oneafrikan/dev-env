# ─────────────────────────────────────────────
# bootstrap/arch.sh — Arch Linux package install
# Sourced by bootstrap.sh (not executed). Only what mise can't provide is
# installed natively (packages/pacman.txt, packages/aur.txt); the CLI tools
# come from mise via config/mise.toml.
# ─────────────────────────────────────────────

platform_packages() {
  log "Installing pacman packages (packages/pacman.txt)..."
  local pkgs
  pkgs="$(pkgs_from "$DEV_ENV/packages/pacman.txt" | tr '\n' ' ')"
  # --needed: already-installed packages are skipped, so a re-run is a no-op
  # shellcheck disable=SC2086
  run sudo pacman -S --needed --noconfirm $pkgs
  did "pacman packages installed"
}

platform_ensure_mise() {
  log "Ensuring mise..."
  if command -v mise &>/dev/null; then
    ok "mise already installed ($(mise --version 2>/dev/null | head -1))"
  else
    run sudo pacman -S --needed --noconfirm mise
    did "mise installed"
  fi
}

# Desktop only — bootstrap.sh skips this when headless.
platform_desktop() {
  log "Installing desktop apps (packages/aur.txt)..."
  local pkgs
  pkgs="$(pkgs_from "$DEV_ENV/packages/aur.txt" | tr '\n' ' ')"
  # Cursor is opt-in (--with-cursor / DEV_ENV_WITH_CURSOR=1), not in aur.txt.
  [[ "$WITH_CURSOR" == 1 ]] && pkgs="$pkgs cursor-bin"
  if ! command -v yay &>/dev/null; then
    warn "yay not found — skipping desktop apps: $pkgs"
    return 0
  fi
  # AUR builds are interactive on purpose (PKGBUILD review); no --noconfirm.
  # shellcheck disable=SC2086
  run yay -S --needed $pkgs
  [[ "$WITH_CURSOR" == 1 ]] && CURSOR_PLANNED=1   # so the git-editor step knows (dry-run)
  did "desktop apps installed"
}
