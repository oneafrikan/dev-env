# CLAUDE.md — api/

## Purpose

External API health checks and key management. Verify connectivity before starting work.

## Conventions

- check-keys.sh is called by on-start.sh — keep it fast and non-blocking
- Never print key values — only ✓/✗ with key name

## Dependencies

- `op` — 1Password CLI for key retrieval
- `llm` CLI — for Anthropic connectivity test

## Scripts

| Name                  | Status      | Description                               |
|-----------------------|-------------|-------------------------------------------|
| check-keys.sh         | implemented | Test Anthropic, op signin, .env presence  |
| token-expiry.sh       | stub        | Check OAuth token expiry dates            |
| rotate-secrets.sh     | stub        | Rotate API keys via 1Password             |
| rate-limit-headroom.sh| stub        | Check remaining API rate limits           |
| ngrok-manager.sh      | stub        | Start/stop ngrok tunnels                  |
| close-hung.sh         | stub        | Close hung API connections                |
| api-latency.sh        | stub        | Measure API response times                |

## Secrets

Anthropic key: `llm keys set anthropic`
1Password: `op signin` required
