#!/usr/bin/env python3
"""Recursively find and delete all *_INDEX.md files from an Obsidian vault.

Usage:
    python3 clean_obsidian_index_files.py              # Dry run — list files that would be deleted
    python3 clean_obsidian_index_files.py --delete      # Actually delete the files
    python3 clean_obsidian_index_files.py /path/to/vault --delete  # Custom vault path
"""

import argparse
import sys
from pathlib import Path

DEFAULT_VAULT = "/Users/you/Obsidian/MyVault"


def find_index_files(vault_path: Path) -> list[Path]:
    return sorted(vault_path.rglob("*_INDEX.md"))


def main():
    parser = argparse.ArgumentParser(
        description="Clean up _INDEX_*.md files from an Obsidian vault."
    )
    parser.add_argument(
        "vault",
        nargs="?",
        default=DEFAULT_VAULT,
        help=f"Path to the vault (default: {DEFAULT_VAULT})",
    )
    parser.add_argument(
        "--delete",
        action="store_true",
        help="Actually delete the files. Without this flag, runs in dry-run mode.",
    )
    args = parser.parse_args()

    vault_path = Path(args.vault).resolve()
    if not vault_path.is_dir():
        print(f"Error: {vault_path} is not a directory", file=sys.stderr)
        sys.exit(1)

    files = find_index_files(vault_path)

    if not files:
        print("No _INDEX_*.md files found.")
        return

    if args.delete:
        for f in files:
            f.unlink()
            print(f"Deleted: {f.relative_to(vault_path)}")
        print(f"\n{len(files)} file(s) deleted.")
    else:
        print("Dry run — files that would be deleted:\n")
        for f in files:
            print(f"  {f.relative_to(vault_path)}")
        print(f"\n{len(files)} file(s) found. Re-run with --delete to remove them.")


if __name__ == "__main__":
    main()
