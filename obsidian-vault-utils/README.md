# Obsidian Vault Management Scripts

Daily-note workflow for the primary vault, plus index generation and backup
across every vault. Active vaults for indexing/backup are configured in
`vaults.conf`. (Merged from the former `vault/` and `vault-obsidian-utils/`
directories — same domain, no reason to keep them split.)

## What's included

| Script | Purpose |
|--------|---------|
| `daily-note.sh` | Create/open today's daily note in Obsidian |
| `capture.sh "note"` | Append a quick note to `inbox/capture.md` |
| `search.sh "query"` | rg + fzf search, opens result in Obsidian |
| `backfill-daily-note-frontmatter.py` | Backfill frontmatter on existing daily notes |
| `build_obsidian_vault_index.py [vault]` | Generates Dataview-based navigational index files throughout a vault |
| `clean_obsidian_index_files.py [vault] [--delete]` | Deletes all `_INDEX_*.md` files (dry-run by default, `--delete` to confirm) |
| `sync_obsidian_V2.sh [vault]` | Creates timestamped ZIP backups to Google Drive with an extracted shadow copy |
| `run_all.sh [vault]` | Cleans, rebuilds indexes, and backs up — all vaults or just one |
| `vaults.conf` | Lists active vault paths, one per line |

## Daily workflow (primary vault)

```bash
bash daily-note.sh              # create/open today's daily note
bash capture.sh "quick idea"    # append to inbox/capture.md
bash search.sh "query"          # rg + fzf search, opens result in Obsidian
```

These three always target the primary vault (`~/Obsidian/MyVault`),
regardless of `vaults.conf`.

## Index & backup (all vaults)

Process all vaults:

```bash
bash run_all.sh
```

Process a single vault:

```bash
bash run_all.sh /path/to/vault
```

Or run scripts individually:

```bash
python3 clean_obsidian_index_files.py /path/to/vault              # Dry run — list index files
python3 clean_obsidian_index_files.py /path/to/vault --delete      # Delete all index files
python3 build_obsidian_vault_index.py /path/to/vault               # Regenerate indexes
bash sync_obsidian_V2.sh /path/to/vault                            # Backup to Google Drive
```

All scripts default to `MyVault` if no vault path is given.

## Adding a new vault

`vaults.conf` is gitignored (machine-specific). If it doesn't exist yet:

```bash
cp vaults.conf.example vaults.conf
```

Then add the vault's path, one per line:

```
/Users/you/Obsidian/My_New_Vault
```

## How it works

### Index generation
- Creates `_INDEX_{folder-name}.md` in each folder using Dataview TABLE queries (not wikilinks) — this keeps the graph view clean by avoiding artificial edges
- Each index shows notes with their last-modified date, making it easy to find stale content
- Subfolder links between index files provide a lightweight structural spine in the graph
- Generates a top-level `INDEX.md` linking to all major folder indexes
- Generates `INDEX_Full_Structure.md` with the complete vault tree
- Renames any legacy `Index.md` files to the new naming convention

### Cleanup
- `clean_obsidian_index_files.py` removes all `_INDEX_*.md` files recursively
- Defaults to dry-run mode; pass `--delete` to actually remove files

### Backup
- Creates a timestamped ZIP (`{VaultName}_YYYYMMDD_HHMMSS.zip`) in Google Drive
- Extracts a readable shadow copy per vault at `ObsidianShadow/{VaultName}/`
- Excludes `.DS_Store`, `.trash`, and `.obsidian/workspace.json`

## Requirements

- Python 3 (stdlib only, no venv needed)
- Google Drive for desktop (mounted at the default macOS path)
