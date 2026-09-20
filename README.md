# dev-env

A personal Mac/Ubuntu/Arch developer environment — one command gets you into a
fully-formed working context. It's not a framework; it's one person's
opinionated set of scripts for daily friction. Fork it for your own.

## What you get

**45 implemented scripts, 27 domains** — plus 65 more already scaffolded and
marked `NOT IMPLEMENTED`, ready for whoever needs that one next
(`just stubs` lists them). Batteries partially included, on purpose: the
conventions and structure are done, the long tail of niche scripts is a
todo list, not a gap.

A sample across domains:

| Domain | Examples |
|---|---|
| Daily workflow | `ctx <name>`, `just morning`/`status`/`end`, `git/standup.sh`, `git/multi-status.sh` |
| System hygiene | `secrets/secret-scan.sh`, `python/venv-audit.sh`, `services/killport.sh`, `files/find-dupes.sh` |
| Terminal & desktop | per-machine iTerm2 profiles, Hammerspoon Space-switching, tmux config, Ghostty config |
| Data & LLM | `llm/run.sh` — one wrapper, model-agnostic, every script calls it instead of a provider CLI directly |
| Self-hosted tools | `uptime-kuma/` monitoring bootstrap, `tailscale/` status, `obsidian-vault-utils/` (daily notes, index, backup) |
| Repo self-maintenance | `meta/stub-audit.sh`, `meta/validate-contexts.sh` |

This is a sample, not the full list — browse the **Repo layout** below, or
just `ls` each domain folder; every one has its own `CLAUDE.md`.

## How it works

Everything hangs off one entry point, `ctx <name>` (defined in
`shell/functions.zsh`), which runs `contexts/<name>.sh` — a script that
switches macOS Space, opens your editor/terminal workspace, and lands you in
a project. `Justfile` wraps the rest of the scripts as `just <recipe>` so
nothing needs to be memorized as a raw path. `bootstrap.sh` is the one-shot
new-machine setup: installs tools, symlinks dotfiles, wires the shell.

| Piece | Role |
|---|---|
| `bootstrap.sh` | One-shot new-machine setup — idempotent, safe to re-run |
| `Justfile` | Task runner — `just <recipe>` in place of remembering script paths |
| `shell/functions.zsh` | Defines `ctx` and a handful of daily-use shell functions |
| `contexts/*.sh` | One script per project — the actual `ctx` targets (bring your own) |
| Everything else | Domain-scoped utility scripts, one folder per domain |

## Getting started

One command — clone, then bootstrap:

```bash
git clone https://github.com/oneafrikan/dev-env.git ~/.dev-env \
  && bash ~/.dev-env/bootstrap.sh
```

That installs your tools, symlinks dotfiles, and wires your shell rc. It picks
the platform itself — macOS (Homebrew + `Brewfile`), Ubuntu (apt + mise) or Arch
(pacman/yay + mise) — and on Linux skips GUI apps when there's no desktop
session. Preview any run first with `bash ~/.dev-env/bootstrap.sh --dry-run`
(prints every action, changes nothing). Overrides for odd setups:
`DEV_ENV_OS=darwin|ubuntu|arch`, `DEV_ENV_HEADLESS=0|1`. Then:

```bash
llm keys set anthropic     # set your Anthropic API key
op signin                  # sign into 1Password CLI
source ~/.zshrc            # reload shell

tmux new-session           # install tmux plugins: prefix + I (Ctrl+A then Shift+I)

ctx example                # try the template context
```

## Daily usage

```bash
ctx <name>       # jump into a project (copy contexts/example.sh to build your own)
just morning     # standup digest + disk/key checks
just status      # all repo statuses at a glance
just end         # WIP commits + session note
just stubs       # list every NOT IMPLEMENTED script
```

## Private counterpart

Not everything belongs in a public repo. This is the public half of a
two-repo split — a private counterpart holds real machine names, IPs,
employer-specific scripts, and credentials, and never leaves it. Nothing
about the *mechanism* here is private, only the content: `contexts/*.sh` and
`scripts/iterm2-profiles/profiles/*.json` are gitignored except for their
`example.*` template, exactly like a real machine's copies would be if you
forked this.

That separation is the point — fork this repo and your own private setup
never touches its history. Nothing here was ever committed to a private
repo and later "cleaned" for publishing; the public and private repos have
been two separate git histories from the start.

## Repo layout

```
~/.dev-env/
  contexts/
    example.sh              ← template; contexts/*.sh gitignored except this one
  scripts/iterm2-profiles/
    setup.sh                ← symlinks the right profile in based on hostname
    profiles/
      example.json          ← template; profiles/*.json gitignored except this one
  obsidian-vault-utils/
    vaults.conf.example     ← tracked template
    vaults.conf             ← GITIGNORED, personal — your own vault list
  uptime-kuma/
    monitors.json.example   ← tracked template
    monitors.json           ← GITIGNORED, personal — your own monitor list
  session/                  ← start/end of day automation
  llm/                      ← model-agnostic LLM wrapper + templates
  git/, services/, secrets/, network/, python/,
  macos/, monitor/, files/, data/, api/         ← one folder per domain, own CLAUDE.md each
  hammerspoon/, tmux/, tailscale/, dropbox/, fabric/
  shell/                    ← functions.zsh (ctx, aliases) + aliases.zsh
  meta/                     ← repo self-maintenance (stub-audit, validate-contexts)
  lib/                      ← shared bash utilities (platform.sh)
  __prompts/                ← the original AI prompt that built this repo
  bootstrap.sh              ← one-shot new-machine setup
  Justfile                  ← task runner
  CLAUDE.md                 ← full project context for AI coding agents
```

## Contributing scripts

The natural pattern for adding a script from another machine:

```bash
git clone https://github.com/oneafrikan/dev-env.git ~/.dev-env

# Drop it into the right domain folder (e.g. obsidian-vault-utils/)
# Match conventions: set -euo pipefail, log/ok/warn/err helpers, chmod +x
git add obsidian-vault-utils/my-script.sh
git commit -m "feat(vault): add my-script"
git push
```

Scripts that work across contexts belong here. Scripts tied to a single
project belong in that project's own repo.

## Status & expectations

This is one person's working system, shared because the mechanics are
reusable — not a supported product. Concretely:

- **It will change under you.** No versioning, no deprecation cycle.
- **It is opinionated.** The folder-per-domain layout, the `ctx`/`Justfile`
  split, and the logging conventions are all one person's choices, not a
  consensus design.
- **Personal config is gitignored, not mixed in.** `contexts/*.sh`,
  `scripts/iterm2-profiles/profiles/*.json`, `vaults.conf`, and
  `monitors.json` are all personal and untracked — you get a generic
  `example.*`/`.example` starting point for each. A fork never inherits
  Gareth's machine names, project roots, or account routing.
- **Fork rather than depend.** The `ctx`/`Justfile`/`bootstrap.sh` pattern is
  the transferable part. Copy it and point it at your own projects.

## License

[MIT](LICENSE).

## Owner

Gareth Knight — oneafrikan
