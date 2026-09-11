# CLAUDE.md — session/

## Purpose

Start/end of day automation and session management. Scripts here orchestrate other domain scripts to give a complete daily workflow.

## Conventions

- Scripts are orchestrators — they call domain scripts, not reimplemented
- Non-blocking: on-start uses `|| warn` so partial failures don't abort the whole session

## Dependencies

- `llm/run.sh` — session-note and morning-digest pipe through LLM
- `git/multi-status.sh`, `api/check-keys.sh`, `monitor/disk-monitor.sh`
- Vault root at `~/Obsidian/MyVault/inbox/`

## Scripts

| Name                 | Status      | Description                                    |
|----------------------|-------------|------------------------------------------------|
| on-start.sh          | implemented | Start-of-day: status, keys, disk, digest       |
| on-end.sh            | implemented | End-of-day: WIP commits, session note          |
| morning-digest.sh    | implemented | Git standup + disk + macOS updates via LLM     |
| wip-commit.sh        | implemented | WIP commit all dirty context repos             |
| session-note.sh      | implemented | Generate and append vault session note         |
| stale-branches.sh    | stub        | Report branches not touched recently           |
| sync-all-repos.sh    | stub        | Pull latest on all context repos               |
| rotate-keys-reminder | stub        | Remind about key rotation schedule             |
| idle-watch.sh        | stub        | Alert when machine idle too long               |

## Secrets

No secrets directly — delegates to api/check-keys.sh.
