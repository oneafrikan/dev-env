# Uptime Kuma — Homelab Monitoring

Self-hosted uptime monitoring via Docker, with a bootstrap script to recreate all
monitors + a public status page from a config file.

## Stack

- `docker-compose.yml` — single-container Uptime Kuma setup, port 3001, data persisted to `./uptime-kuma-data/`
- `setup_monitors.py` — bootstrap script: creates all monitors + status page on a fresh instance, from `monitors.json`
- `monitors.json.example` — template config; copy to `monitors.json` (gitignored) and edit with your own hosts

## Running

```bash
# Start the container
docker compose up -d

# Configure your monitors (once)
cp monitors.json.example monitors.json
# edit monitors.json with your own hosts/IPs

# Bootstrap monitors (run once after creating admin account in the web UI)
python3 setup_monitors.py <username> <password>
```

## Config format

`monitors.json` has two top-level keys:

- `status_page` — slug, title, description, theme for the public status page
- `monitors` — list of `{"type": "ping"|"http", "name": ..., "hostname"|"url": ..., "interval": ...}`
  entries. HTTP monitors also accept `accepted_statuscodes`, `ignoreTls`, `maxredirects`.

The script is **idempotent** — re-running it updates existing monitors (matched by
`name`) instead of duplicating them, and always refreshes the status page.

## Adding new monitors

Add an entry to `monitors.json` and re-run `setup_monitors.py`. The `name` must be
unique — it's used to detect existing monitors.

## Dependencies

```bash
pip3 install uptime-kuma-api --break-system-packages
```

## Notes

- Data directory is at `./uptime-kuma-data/` — not committed to git
- A self-signed TLS cert on a monitored host needs `"ignoreTls": true` on its HTTP monitor
