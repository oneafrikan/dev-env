# CLAUDE.md — git/

## Purpose

Git workflow automation across all context repos. Multi-repo status, AI commit messages, branch hygiene.

## Conventions

- All scripts operate on all 5 repos by default: project-a, project-b, vault, project-c, dev-env
- standup.sh accepts --raw to skip LLM and output plain git log

## Dependencies

- `llm/run.sh` — standup and commit-msg pipe through LLM
- `git` — obviously

## Scripts

| Name              | Status      | Description                                    |
|-------------------|-------------|------------------------------------------------|
| standup.sh        | implemented | Yesterday's commits across all repos + AI sum  |
| commit-msg.sh     | implemented | AI-suggested commit message with y/N/edit      |
| multi-status.sh   | implemented | Branch, ahead/behind, dirty status for all repos|
| branch-hygiene.sh | implemented | Prune merged and stale branches interactively  |
| .gitconfig        | implemented | Git config template (copy to ~/.gitconfig)     |
| sync-all.sh       | stub        | Pull all repos                                 |
| stale-prs.sh      | stub        | List PRs with no activity                      |
| install-hooks.sh  | stub        | Install pre-commit hooks across repos          |
| auto-tag.sh       | stub        | Auto-tag release versions from commits         |

## Secrets

None.
