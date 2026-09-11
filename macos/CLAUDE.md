# CLAUDE.md — macos/

## Purpose

macOS system management utilities. These scripts are macOS-only — they guard with platform checks and exit gracefully on Linux.

## Conventions

- All scripts: check `uname -s` == Darwin before doing anything
- Use osascript for system-level automation (Focus, Space, etc.)

## Dependencies

- macOS — all scripts exit gracefully on Linux
- `caffeinate` — built into macOS
- Hammerspoon — for Space switching (see hammerspoon/)
- `softwareupdate` — macOS update check

## Scripts

| Name                  | Status      | Description                              |
|-----------------------|-------------|------------------------------------------|
| caffeinate.sh         | implemented | Prevent sleep with optional duration     |
| dnd.sh                | implemented | Toggle Focus/DND, with auto-disable      |
| app-startup.sh        | stub        | Launch apps in correct order/Space       |
| login-audit.sh        | stub        | Show recent login history                |
| display-profile.sh    | stub        | Switch display resolution/profile        |
| audio-switch.sh       | stub        | Switch audio output device               |
| temp-monitor.sh       | stub        | Monitor CPU/GPU temperature              |
| defaults-audit.sh     | stub        | Audit macOS defaults settings            |
| notification-audit.sh | stub        | Review notification permissions          |

## Secrets

None.
