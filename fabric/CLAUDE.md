# CLAUDE.md — fabric/

## Purpose

Daniel Miessler's fabric framework for applying AI patterns to content. install.sh sets up fabric and links custom patterns.

## Conventions

- Custom patterns live in fabric/patterns/ as .md files
- install.sh symlinks them into ~/.config/fabric/patterns/
- For lighter-weight LLM calls, prefer llm/run.sh with templates/

## Dependencies

- `go` — required to install fabric
- `fabric` — installed via go install

## Scripts

| Name        | Status      | Description                                |
|-------------|-------------|--------------------------------------------|
| install.sh  | implemented | Install fabric + link custom patterns      |

## Secrets

Fabric uses its own API key config — run `fabric --setup` after install.
