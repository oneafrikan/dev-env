# CLAUDE.md — files/

## Purpose

File and disk management. Clean build artifacts, find large files, manage screenshots and archives.

## Conventions

- clean-tmp.sh is dry-run by default — requires --yes to actually delete
- find-large.sh defaults to 100MB threshold

## Dependencies

- `fd` — fast file finder (brew install fd)
- `numfmt` — human-readable sizes

## Scripts

| Name              | Status      | Description                                    |
|-------------------|-------------|------------------------------------------------|
| clean-tmp.sh      | implemented | Remove Python/build artifacts (dry-run default)|
| find-large.sh     | implemented | Find files over size threshold                 |
| archive-logs.sh   | stub        | Compress and archive old log files             |
| find-dupes.sh     | stub        | Find duplicate files by hash                   |
| snapshot.sh       | stub        | Snapshot a directory state                     |
| watch-dir.sh      | stub        | Watch directory and run command on changes     |
| screenshot-clean.sh| stub       | Organise screenshots by date                   |

## Secrets

None.
