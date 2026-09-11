# CLAUDE.md — secrets/

## Purpose

Security and credential hygiene. Scan for leaked secrets, audit .env files, check SSH key ages.

## Conventions

- Never print matched secret values — only file paths and line numbers
- env-audit.sh checks gitignore status for ALL .env files found
- secret-scan.sh uses gitleaks if available, regex fallback if not

## Dependencies

- `gitleaks` — preferred secret scanner (brew install gitleaks)
- `op` — 1Password CLI
- `git` — history scanning in env-audit.sh

## Scripts

| Name                   | Status      | Description                                   |
|------------------------|-------------|-----------------------------------------------|
| env-audit.sh           | implemented | Check .env files are gitignored + not in hist  |
| secret-scan.sh         | implemented | Gitleaks + regex scan across all repos        |
| ssh-key-age.sh         | implemented | Report SSH key ages, flag old keys            |
| perms-audit.sh         | stub        | Check file permissions on sensitive files     |
| app-perms.sh           | stub        | Audit macOS app permissions                   |
| credential-rotation.sh | stub        | Guide through credential rotation             |

## Secrets

Uses `op` for rotation guidance but never stores secrets.
