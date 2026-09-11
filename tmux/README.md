# tmux

tmux is a **terminal multiplexer** — it lets you run multiple terminal sessions inside one SSH connection, split your screen into panes, and crucially: **keep everything running after you disconnect**. If your SSH session drops, tmux keeps your work alive. Reconnect and resume exactly where you left off.

Config lives at `~/.dev-env/tmux/.tmux.conf`, symlinked to `~/.tmux.conf`.

---

## Quick start

```bash
tmux new -s work    # start a named session
# ... do stuff ...
prefix + d           # detach — leave it running, back to plain shell

tmux attach -t work  # come back later, from anywhere with SSH
```

### The mental model in one sentence

The session lives on the machine permanently. You're just connecting a view to it — from any device, anywhere. Close the view, the session keeps running. Reconnect and it's exactly where you left it.

---

## Scripted session layouts (per machine, bring your own)

This repo doesn't ship per-machine session scripts — they're specific to what each of
your machines actually does. The pattern that works well:

- One script per machine (e.g. `tmux-session.sh`) that creates a named session with
  the windows you want pre-opened, using `tmux new-window` / `tmux send-keys`. Make it
  idempotent — check `tmux has-session`/`tmux list-windows` first, only create what's
  missing, so it's safe to re-run.
- A separate, generic *client-side* script (SSH in, attach-or-create the session) if you
  want to reach these sessions from other machines — keep it generic (take host/session
  as arguments) rather than one-off per machine.

Run the per-machine script once to create the layout; tmux-continuum (below) then keeps
the session alive across reboots automatically.

---

## Core mental model

```
Server  →  one tmux process running on the machine
  └── Session  →  a named workspace (e.g. "work", "logs")
        └── Window  →  a tab (numbered 1, 2, 3…)
              └── Pane  →  a split within a window
```

You can have multiple sessions, each with multiple windows, each split into panes. When you disconnect, the server keeps running. When you reconnect, you re-attach to your sessions.

---

## Prefix key

Almost all tmux commands start with the **prefix**: `Ctrl-a`

Press `Ctrl-a`, release, then press the next key. It's not a chord — it's a sequence.

---

## Essential commands — starting out

### Sessions

| Command | What it does |
|---------|-------------|
| `tmux` | Start a new unnamed session |
| `tmux new -s work` | Start a new session named "work" |
| `tmux ls` | List running sessions |
| `tmux attach` or `tmux a` | Re-attach to the last session |
| `tmux attach -t work` | Re-attach to a named session |
| `prefix + d` | **Detach** — leave tmux running, go back to plain shell |
| `prefix + $` | Rename the current session |
| `prefix + s` | Show all sessions (interactive picker) |

> **The most important habit:** always `prefix + d` instead of closing your terminal. Your session survives.

---

### Windows (tabs)

| Command | What it does |
|---------|-------------|
| `prefix + c` | New window (opens in current directory) |
| `prefix + ,` | Rename current window |
| `prefix + &` | Kill current window |
| `prefix + [1–9]` | Jump to window by number |
| `Shift + →` | Next window |
| `Shift + ←` | Previous window |
| `prefix + w` | Show all windows (interactive picker) |

Windows are numbered from 1 (set in config). The current window is marked `*` in the status bar.

---

### Panes (splits)

| Command | What it does |
|---------|-------------|
| `prefix + \|` | Split **right** (vertical divider) |
| `prefix + -` | Split **down** (horizontal divider) |
| `Alt + ←` | Move to left pane |
| `Alt + →` | Move to right pane |
| `Alt + ↑` | Move to pane above |
| `Alt + ↓` | Move to pane below |
| `prefix + x` | Kill current pane (confirm with `y`) |
| `prefix + z` | **Zoom** — maximise/restore current pane |
| `prefix + {` / `prefix + }` | Swap pane left / right |
| `prefix + Space` | Cycle through pane layouts |
| `prefix + q` | Show pane numbers briefly |

> **Zoom (`prefix + z`)** is your friend. When you need to focus on one pane, zoom it. Press again to unzoom.

---

### Copy mode (scrollback + search)

tmux has its own scrollback buffer. Enter it to scroll up, search, and copy.

| Command | What it does |
|---------|-------------|
| `prefix + Enter` | Enter copy mode |
| `q` or `Escape` | Exit copy mode |
| Arrow keys or `j/k` | Scroll line by line |
| `Ctrl-u` / `Ctrl-d` | Scroll half page up / down |
| `Ctrl-b` / `Ctrl-f` | Scroll full page up / down |
| `/` then text | Search forward |
| `?` then text | Search backward |
| `n` / `N` | Next / previous search result |
| `v` | Start visual selection |
| `y` | Yank (copy) selection and exit |

Copy mode uses **vi keys** (configured in the config). If you know vim navigation, muscle memory transfers directly.

---

### Config

| Command | What it does |
|---------|-------------|
| `prefix + r` | Reload `~/.tmux.conf` without restarting |

---

## Plugins (via TPM)

Three plugins are installed and auto-loaded:

| Plugin | What it does |
|--------|-------------|
| `tmux-sensible` | Sane defaults (better terminal handling, faster key repeat) |
| `tmux-resurrect` | **Save and restore sessions across reboots** |
| `tmux-continuum` | Auto-saves session every 15 minutes, auto-restores on start |

### Plugin keybindings

| Command | What it does |
|---------|-------------|
| `prefix + Ctrl-s` | Manually save session (resurrect) |
| `prefix + Ctrl-r` | Manually restore session (resurrect) |
| `prefix + I` | Install new plugins (capital i) |
| `prefix + U` | Update plugins |
| `prefix + Alt-u` | Uninstall removed plugins |

> **tmux-continuum** saves automatically every 15 minutes and restores on startup. You generally don't need to think about it.

---

## Recommended workflow

```bash
# First time — create named sessions for your work areas
tmux new -s monitor     # logs / monitoring
tmux new -s dev         # code editing
tmux new -s ops         # ad-hoc commands

# Detach when done
prefix + d

# Come back later (from SSH or after reboot)
tmux attach -t dev
```

Inside a session, split as needed:
```
┌─────────────────────┬──────────────────┐
│                     │                  │
│  docker logs -f     │  git log         │
│  my-service         │                  │
│                     ├──────────────────┤
│                     │                  │
│                     │  vim CLAUDE.md   │
│                     │                  │
└─────────────────────┴──────────────────┘
    prefix + |  →  split right
    prefix + -  →  split down (in right pane)
```

---

## Quick-start one-liner

```bash
tmux new -s main
```

Then: `prefix + |` to split, `prefix + c` for a new tab, `prefix + d` to detach. That's 90% of daily usage.

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Plugins not loading | Run `prefix + I` to install them |
| Config change not taking effect | `prefix + r` to reload |
| Colours look wrong | Make sure your SSH client sets `$TERM=xterm-256color` |
| Escape key is slow in vim | Already fixed — `escape-time 0` is set in config |
| Can't scroll up | Enter copy mode with `prefix + Enter`, then use arrow keys |
