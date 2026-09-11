# CLAUDE.md — tmux/

## Purpose

tmux configuration. Symlinked to ~/.tmux.conf by bootstrap.sh.

## Conventions

- Prefix: Ctrl+A
- 1-indexed windows and panes
- Zero escape delay (set escape-time 0) — required for Vim/Cursor

## Key bindings

| Binding           | Action                    |
|-------------------|---------------------------|
| prefix + \|       | Vertical split            |
| prefix + -        | Horizontal split          |
| Alt + arrows      | Pane navigation           |
| Shift + arrows    | Window navigation         |
| prefix + r        | Reload config             |

## Dependencies

- TPM (tmux-plugins/tpm) — installed by bootstrap.sh
- tmux-resurrect, tmux-continuum — auto-restored sessions

## Scripts

| Name            | Location                                    | Status      | Description                                          |
|-----------------|---------------------------------------------|-------------|------------------------------------------------------|
| `.tmux.conf`    | `tmux/.tmux.conf`                           | implemented | Full config, symlinked to `~/.tmux.conf`             |

Per-machine session scripts and a remote-attach client script aren't included — see
`README.md`'s "Scripted session layouts" section for the pattern to build your own.

## Organisational split — client vs. server, if you build the per-machine pattern

If you add per-machine session scripts, the split that works well:

- **client-side** — run from any machine to SSH into a remote host and attach its
  session. Belongs with your general connectivity/network tooling.

- **server-side** — run ON the target machine to create or restore its session layout
  (windows, starting commands). Belongs alongside that machine's other operational
  scripts.

One is connectivity, one is workspace definition — worth keeping them separate.

## Secrets

None.
