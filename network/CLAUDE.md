# CLAUDE.md — network/

## Purpose

Connectivity checks for external endpoints and internal network. Quick verification that the services and APIs you depend on are reachable.

## Conventions

- endpoints-up.sh reads network/endpoints.conf (gitignored — use .example as template)
- Timeout: 5 seconds per endpoint

## Dependencies

- `curl` — HTTP checks
- `ping` — basic reachability

## Scripts

| Name               | Status      | Description                                    |
|--------------------|-------------|------------------------------------------------|
| endpoints-up.sh    | implemented | Check external endpoints from endpoints.conf   |
| vpn-status.sh      | stub        | Check VPN connection status                    |
| dns-test.sh        | stub        | Test DNS resolution for key domains            |
| open-connections.sh| stub        | List open network connections                  |
| bandwidth.sh       | stub        | Measure current bandwidth                      |
| port-scan-local.sh | stub        | Scan local network for open ports             |
| ngrok-manager.sh   | stub        | Start/stop ngrok tunnels                       |

## Secrets

None.
