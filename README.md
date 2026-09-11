# dev-env

A personal Mac/Ubuntu developer environment, shared as a public reference.

One command gets you into a fully-formed working context. Scripts solve real daily
friction — nothing decorative.

This is the public half of a two-repo setup — real machine names, IPs, and personal
config live in a private counterpart that isn't published. `contexts/` and
`scripts/iterm2-profiles/profiles/` ship a template only; bring your own for your
actual machines/projects.

## Quick start

```bash
# Enter a context (contexts/example.sh ships as a template — copy it, fill in
# your own project root and Space number, and it's available as `ctx <name>`)
ctx example

# Daily workflow
just morning     # Standup digest + disk/key checks
just status      # All repo statuses at a glance
just end         # WIP commits + session note
```

## New machine setup

```bash
# 1. Clone the repo
git clone git@github.com:oneafrikan/dev-env.git ~/.dev-env

# 2. Bootstrap (installs Homebrew, tools, symlinks dotfiles, wires .zshrc)
cd ~/.dev-env && ./bootstrap.sh

# 3. Set your Anthropic API key
llm keys set anthropic

# 4. Sign into 1Password CLI
op signin

# 5. Reload shell
source ~/.zshrc

# 6. Install tmux plugins (inside a tmux session)
tmux new-session
# then press: prefix + I   (Ctrl+A then Shift+I)

# 7. Try the example context
ctx example
```

## Structure

| Folder                  | Purpose                                                |
|--------------------------|--------------------------------------------------------|
| `contexts/`              | Context activation scripts (template only — see above) |
| `session/`               | Start/end of day automation (`just morning`/`end`)      |
| `llm/`                   | LLM wrapper and templates                               |
| `git/`                   | Git workflow utilities                                  |
| `services/`              | Process and port management                             |
| `api/`                   | API key health checks                                   |
| `data/`                  | Data engineering utilities                               |
| `python/`                | Python environment management                            |
| `secrets/`               | Security and credential hygiene                          |
| `network/`               | Connectivity checks                                      |
| `files/`                 | File and disk management                                 |
| `obsidian-vault-utils/`  | Obsidian vault utilities (daily notes, index, backup)     |
| `uptime-kuma/`           | Self-hosted uptime monitoring bootstrap                   |
| `tailscale/`             | Tailscale status helper                                   |
| `macos/`                 | macOS system management                                   |
| `monitor/`               | Monitoring and alerting                                   |
| `hammerspoon/`           | Space switching and hotkeys                               |
| `tmux/`                  | tmux config + reference                                   |
| `shell/`                 | zsh functions and aliases                                 |
| `meta/`                  | Repo self-maintenance                                     |
| `lib/`                   | Shared bash utilities (platform.sh)                       |
| `dropbox/`, `fabric/`    | Optional tool installers (Dropbox apt repo, fabric patterns) |
| `config/`, `ghostty/`    | Global gitignore template, Ghostty terminal config       |
| `__prompts/`             | The original AI prompt used to build this repo           |
| `scripts/iterm2-profiles/`| Per-machine iTerm2 profile mechanism (template only)      |

## Contributing scripts

The natural pattern for adding scripts from another machine:

```bash
# On the other machine
git clone git@github.com:oneafrikan/dev-env.git ~/.dev-env

# Drop scripts into the right folder (e.g. obsidian-vault-utils/)
# Match conventions: set -euo pipefail, log/ok/warn/err helpers, chmod +x
# Then commit and push back
git add obsidian-vault-utils/my-script.sh
git commit -m "feat(vault): add my-script"
git push
```

Scripts that work across contexts belong here. Scripts tied to a single project belong in that project's repo.

## Finding stubs

```bash
just stubs       # List all NOT IMPLEMENTED scripts
```

## Owner

Gareth Knight — oneafrikan
