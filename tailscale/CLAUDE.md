# CLAUDE.md — tailscale/

## Purpose

Tailscale command reference and helpers. Tailscale is the mesh VPN connecting this
machine to the rest of the tailnet (peers reachable on 100.x addresses + MagicDNS names).

## Conventions

- Installed via **snap** on this machine — binary at `/snap/bin/tailscale`, daemon
  service `snap.tailscale.tailscaled`.
- State-changing commands need `sudo` (`up`, `down`, `set`, `logout`); read-only
  commands (`status`, `ip`, `ping`, `netcheck`) do not.
- Prefer `tailscale set --flag` to tweak a single preference without re-running `up`.

## Dependencies

- `tailscale` / `tailscaled` — the client and daemon (snap)
- `systemctl` / `journalctl` — manage and inspect the daemon

## Scripts

| Name         | Status      | Description                                   |
|--------------|-------------|-----------------------------------------------|
| ts-status.sh | implemented | One-shot read-only overview: version, IP, status, netcheck |

## Secrets

- Auth keys (`tskey-...`) are sensitive — never commit them. Use them inline only
  for non-interactive `tailscale up --auth-key=...` on servers/CI.
