# CLAUDE.md — hammerspoon/

## Purpose

macOS Space switching and hotkeys via Hammerspoon. Symlinked to ~/.hammerspoon/init.lua by bootstrap.sh.

## Conventions

- macOS only — no Linux equivalent
- Each hotkey switches Space AND opens an iTerm2 tab running `ctx <name>`
- `switchContext(space, contextName)` is the reusable helper — add one
  `hs.hotkey.bind` call per `contexts/<name>.sh` script you create

## Hotkeys

| Shortcut      | Action                        |
|---------------|--------------------------------|
| Ctrl+Shift+R  | Reload Hammerspoon config      |

Add your own context hotkeys below the commented example in `init.lua`.
