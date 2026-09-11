# CLAUDE.md — llm/

## Purpose

Central LLM wrapper and configuration. All scripts that call an LLM must use `llm/run.sh` — never call `llm` directly. This ensures model selection is managed in one place.

## Conventions

- Model priority: `-m` flag > `LLM_MODEL` env var > `config.sh` DEFAULT_MODEL > hardcoded fallback
- Templates are plain-text system prompts in `templates/`
- `config.sh` is sourced, not executed — edit it to change defaults globally

## Dependencies

- `llm` CLI — install via `uv tool install llm`
- `llm-anthropic`, `llm-gemini` plugins
- `ttok` (optional) — token counting
- `Ollama` (optional) — for `--local` mode

## Scripts

| Name        | Status      | Description                                  |
|-------------|-------------|----------------------------------------------|
| run.sh      | implemented | Central LLM wrapper — all scripts use this   |
| config.sh   | implemented | Model defaults and provider config           |

## Templates

| Name               | Description                                    |
|--------------------|------------------------------------------------|
| commit-message.txt | Conventional commits format                    |
| standup.txt        | Extract done/blocked/next from git log         |
| error-explain.txt  | Explain error, likely cause, suggested fix     |
| data-summary.txt   | Dataset shape, nulls, anomalies                |
| session-note.txt   | Vault-ready session note from activity         |
| code-review.txt    | Bugs, security, style                          |
| release-notes.txt  | Release notes from conventional commits        |
| security-audit.txt | Credentials, secrets, vulnerabilities          |

## Secrets

Anthropic API key: `llm keys set anthropic` (stored in llm's own keystore, not here).
