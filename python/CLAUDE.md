# CLAUDE.md — python/

## Purpose

Python environment management across all context projects. Audit venvs, check for outdated packages, run security audits.

## Conventions

- Python version is pinned in .python-version (3.12.3)
- base-requirements.txt is installed into every new venv by mkvenv
- Use `uv` everywhere — not pip directly

## Dependencies

- `uv` — fast Python package manager
- `pyenv` — Python version management
- `pip-audit` — vulnerability scanning

## Scripts

| Name              | Status      | Description                                   |
|-------------------|-------------|-----------------------------------------------|
| venv-audit.sh     | implemented | Check venv existence and outdated packages     |
| security-audit.sh | implemented | pip-audit for all context venvs               |
| dep-conflicts.sh  | stub        | Find dependency version conflicts             |
| find-non-uv.sh    | stub        | Find venvs not managed by uv                  |
| dead-code.sh      | stub        | Find dead code with vulture                   |
| type-coverage.sh  | stub        | Report mypy type coverage                     |
| test-all.sh       | stub        | Run pytest across all projects                |

## Secrets

None.
