# CLAUDE.md — meta/

## Purpose

Repo self-maintenance. Find stubs, validate context scripts, update the repo itself.

## Conventions

- stub-audit.sh is the canonical way to find what needs building next
- validate-contexts.sh is run at the end of bootstrap.sh

## Dependencies

- `grep` — stub detection
- `git` — context validation

## Scripts

| Name                | Status      | Description                                   |
|---------------------|-------------|-----------------------------------------------|
| stub-audit.sh       | implemented | List all NOT IMPLEMENTED scripts by folder    |
| validate-contexts.sh| implemented | Validate all context scripts are consistent   |
| self-update.sh      | stub        | Pull latest dev-env repo                      |
| tool-versions.sh    | stub        | Report installed tool versions                |
| unused-aliases.sh   | stub        | Find aliases pointing to non-existent scripts |
| claude-md-lint.sh   | stub        | Check all CLAUDE.md files exist and have content|

## Secrets

None.
