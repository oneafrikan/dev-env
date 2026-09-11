# CLAUDE.md — monitor/

## Purpose

Monitoring and alerting. disk-monitor checks volumes; alert-router is the single alerting entry point — all other scripts should route through it.

## Conventions

- All alerts go through alert-router.sh, never echo directly
- alert-router severity levels: info → stdout, warn → stdout+log, crit → stdout+log+ntfy
- Alert log: ~/.dev-env-alerts.log (gitignored)

## Dependencies

- `df` — disk usage
- `curl` — ntfy delivery for critical alerts
- `NTFY_TOPIC` env var — optional, for mobile notifications

## Scripts

| Name              | Status      | Description                                  |
|-------------------|-------------|----------------------------------------------|
| alert-router.sh   | implemented | Centralised alerting (stdout/log/ntfy)       |
| disk-monitor.sh   | implemented | Disk usage for /, ~, NAS mounts              |
| cron-health.sh    | stub        | Check cron job success/failure               |
| memory-logger.sh  | stub        | Log memory usage over time                   |
| uptime-tracker.sh | stub        | Track system uptime                          |
| login-monitor.sh  | stub        | Alert on new logins                          |
| process-logger.sh | stub        | Log process lifecycles                       |

## Secrets

`NTFY_TOPIC` — set in .env or environment for mobile push alerts.
