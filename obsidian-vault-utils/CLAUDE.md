# CLAUDE.md — obsidian-vault-utils/

## Purpose

Obsidian vault utilities — daily notes and quick capture for the primary vault,
plus index generation and backup across all vaults. Merged from the former
`vault/` (single-vault daily workflow) and `vault-obsidian-utils/` (multi-vault
maintenance) directories — same domain, no reason to keep them split.

## Conventions

- Primary vault root: `~/Obsidian/MyVault`
- Daily notes land in: `50-Daily-Notes/YYYY-MM-DD.md`
- Captures append to: `inbox/capture.md`
- Session notes append to: `inbox/session-notes.md`
- Active vaults for indexing/backup are listed in `vaults.conf` (one path per line,
  `#` comments and blank lines supported)
- Index files are named `{parent-folder}_INDEX.md` — folder name first so each
  GraphView node is identifiable by folder, not a uniform `_INDEX_` prefix
- Index files use Dataview TABLE queries instead of wikilinks, so they don't
  pollute the graph view — only subfolder links between index files create edges
- Run shell scripts with `bash`, not `python3`

## Dependencies

- `rg` (ripgrep) — vault search
- `fzf` — interactive selection in `search.sh`
- `Obsidian` — opened via URL scheme on macOS
- Python 3, stdlib only — no venv needed
- Google Drive for desktop (mounted at the default macOS path) — backup target

## Scripts

| Name                                | Status      | Description                                                          |
|--------------------------------------|-------------|-----------------------------------------------------------------------|
| `daily-note.sh`                     | implemented | Create/open today's daily note in Obsidian                            |
| `capture.sh`                        | implemented | Append quick note to `inbox/capture.md`                               |
| `search.sh`                         | implemented | rg + fzf search, opens result in Obsidian                             |
| `backfill-daily-note-frontmatter.py`| implemented | Backfill frontmatter on existing daily notes                          |
| `build_obsidian_vault_index.py`     | implemented | Generate `{folder-name}_INDEX.md` files + full structure file, per vault |
| `clean_obsidian_index_files.py`     | implemented | Delete all `*_INDEX.md` files (dry-run by default, `--delete` to confirm) |
| `sync_obsidian_V2.sh`               | implemented | Timestamped ZIP backup to Google Drive + extracted shadow copy        |
| `run_all.sh`                        | implemented | Per vault in `vaults.conf` (or one given): clean → rebuild index → backup |
| `weekly-review.sh`                  | stub        | Generate weekly review template                                       |
| `orphans.sh`                        | stub        | Find notes with no incoming links                                     |
| `tag-audit.sh`                      | stub        | Report tag usage and consistency                                      |
| `word-count.sh`                     | stub        | Word count stats across the vault                                     |
| `Archived/sync_obsidian.sh`         | deprecated  | V1 sync using rsync — superseded by `sync_obsidian_V2.sh`              |

## Key paths

- Vaults: `~/Obsidian/` (`MyVault`, `WorkVault`, `PersonalVault`, others per `vaults.conf`)
- Backups: `Google Drive/ObsidianBackups/` (flat dir, vault name in filename)
- Shadow copies: `Google Drive/ObsidianShadow/{VaultName}/`

## Notes

- `daily-note.sh` / `capture.sh` / `search.sh` operate on the primary vault only
  (`MyVault`); the index/backup scripts operate across every vault in
  `vaults.conf`.
- Run `clean_obsidian_index_files.py --delete` before regenerating indexes, to
  remove stale `*_INDEX.md` files first.
- To add a new vault to indexing/backup, add its path to `vaults.conf` (gitignored —
  copy `vaults.conf.example` first if it doesn't exist yet).

## Secrets

None.
