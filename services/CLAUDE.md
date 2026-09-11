# CLAUDE.md — services/

## Purpose

Process and service management. Start, stop, inspect, and health-check local development services.

## Conventions

- health-check.sh reads services/services.conf (gitignored — use services.conf.example as template)
- killport uses graceful SIGTERM before SIGKILL with 3s wait

## Dependencies

- `lsof` / `ss` — port inspection
- `curl` — HTTP health checks

## Scripts

| Name             | Status      | Description                              |
|------------------|-------------|------------------------------------------|
| killport.sh      | implemented | Kill process on a port (SIGTERM+SIGKILL) |
| ports.sh         | implemented | List all listening ports as a table      |
| health-check.sh  | implemented | Check services from services.conf        |
| svc.sh           | stub        | Service lifecycle manager                |
| watch-pid.sh     | stub        | Watch a PID and alert on exit            |
| kill-zombies.sh  | stub        | Clean up zombie processes                |
| process-order.sh | stub        | Start services in dependency order       |
| mem-threshold.sh | stub        | Alert when process exceeds memory limit  |

## Secrets

None.
