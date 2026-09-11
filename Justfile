# ─────────────────────────────────────────────
# dev-env Justfile
# just <recipe> to run anything
# ─────────────────────────────────────────────

# List all available recipes
default:
  @just --list

# ── Setup ─────────────────────────────────────
bootstrap:
  ./bootstrap.sh

update:
  ./meta/self-update.sh

tool-versions:
  ./meta/tool-versions.sh

validate:
  ./meta/validate-contexts.sh
  ./meta/claude-md-lint.sh

stubs:
  ./meta/stub-audit.sh

iterm2:
  ./scripts/iterm2-profiles/setup.sh

# ── Status (combined health check) ────────────
status:
  ./git/multi-status.sh
  ./monitor/disk-monitor.sh
  ./api/check-keys.sh

# ── Morning / end of day ──────────────────────
morning:
  ./session/on-start.sh
  ./session/morning-digest.sh

end:
  ./session/on-end.sh

# ── Contexts ──────────────────────────────────
# Add a recipe per contexts/<name>.sh you create — or just use `ctx <name>` directly.
example:
  ./contexts/example.sh

# ── Session ───────────────────────────────────
start:
  ./session/on-start.sh

digest:
  ./session/morning-digest.sh

wip:
  ./session/wip-commit.sh

note:
  ./session/session-note.sh

# ── Git ───────────────────────────────────────
standup:
  ./git/standup.sh

multi-status:
  ./git/multi-status.sh

commit-msg repo=".":
  ./git/commit-msg.sh {{repo}}

branches:
  ./git/branch-hygiene.sh

sync:
  ./git/sync-all.sh

# ── Services ──────────────────────────────────
ports:
  ./services/ports.sh

health:
  ./services/health-check.sh

killport port:
  ./services/killport.sh {{port}}

# ── API ───────────────────────────────────────
check-keys:
  ./api/check-keys.sh

# ── Data ──────────────────────────────────────
inspect file:
  ./data/inspect.sh {{file}}

freshness dir="":
  ./data/freshness-check.sh {{dir}}

catalogue:
  ./data/catalogue.sh

validate-export file:
  ./data/validate-export.sh {{file}}

# ── Python ────────────────────────────────────
venv-audit:
  ./python/venv-audit.sh

py-security:
  ./python/security-audit.sh

test-all:
  ./python/test-all.sh

# ── Security ──────────────────────────────────
scan-secrets:
  ./secrets/secret-scan.sh

env-audit:
  ./secrets/env-audit.sh

ssh-key-age:
  ./secrets/ssh-key-age.sh

security:
  ./secrets/secret-scan.sh
  ./python/security-audit.sh
  ./secrets/env-audit.sh

# ── Network ───────────────────────────────────
endpoints:
  ./network/endpoints-up.sh

# ── Files ─────────────────────────────────────
clean:
  ./files/clean-tmp.sh

clean-force:
  ./files/clean-tmp.sh --yes

find-large dir="~":
  ./files/find-large.sh {{dir}}

# ── Vault ─────────────────────────────────────
daily:
  ./obsidian-vault-utils/daily-note.sh

capture note:
  ./obsidian-vault-utils/capture.sh "{{note}}"

search query:
  ./obsidian-vault-utils/search.sh "{{query}}"

orphans:
  ./obsidian-vault-utils/orphans.sh

# ── macOS ─────────────────────────────────────
caffeinate duration="":
  ./macos/caffeinate.sh {{duration}}

dnd action="status":
  ./macos/dnd.sh {{action}}

temp:
  ./macos/temp-monitor.sh

login-audit:
  ./macos/login-audit.sh

# ── Monitor ───────────────────────────────────
disk:
  ./monitor/disk-monitor.sh

# ── Fabric ────────────────────────────────────
fabric-install:
  ./fabric/install.sh
