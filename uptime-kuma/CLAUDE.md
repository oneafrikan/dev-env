# CLAUDE.md — Uptime Kuma Homelab Monitoring

## What this is

Uptime Kuma running in Docker, monitoring homelab machines. This folder contains
the Docker Compose config and a Python bootstrap script that recreates monitors +
a public status page from a config file (`monitors.json`), so a fresh instance
can be rebuilt in one run instead of clicking through the UI.

## Conventions

- `monitors.json` is machine-specific and gitignored — copy `monitors.json.example`
  and fill in real hosts/IPs.
- Monitors are upserted by `name` — re-running the script after editing
  `monitors.json` updates existing monitors instead of duplicating them.

## Dependencies

- Docker + Docker Compose
- `uptime-kuma-api` (Python, via pip) — Socket.IO wrapper the bootstrap script uses

## Scripts

| Name               | Status      | Description                                        |
|--------------------|-------------|-----------------------------------------------------|
| setup_monitors.py  | implemented | Create/update monitors + status page from monitors.json |

## Known quirks

- A monitored host with a self-signed TLS cert needs `"ignoreTls": true` on its HTTP monitor entry.
- The `uptime-kuma-api` library uses camelCase for some params (e.g. `ignoreTls`,
  `accepted_statuscodes`). Check `inspect.signature(UptimeKumaApi._build_monitor_data)`
  if you hit unexpected keyword argument errors.

## Secrets

None in this repo — Uptime Kuma admin credentials are set via its web UI on first run.
