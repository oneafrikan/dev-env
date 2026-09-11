#!/usr/bin/env python3
"""
backfill-daily-note-frontmatter.py

Adds or replaces frontmatter on daily note files (YYYY-MM-DD.md) in Obsidian
vault daily-note folders. Idempotent — safe to re-run.

Targets files named exactly YYYY-MM-DD.md under each vault's 50-Notes tree.
Skips index files, named notes, and anything that doesn't match the date pattern.

Usage:
    python3 backfill-daily-note-frontmatter.py [--dry-run]
"""

import argparse
import logging
import os
import re
import sys
from pathlib import Path

OBSIDIAN_BASE = os.path.expanduser("~/Obsidian")

VAULT_CONFIG = [
    {
        "vault_path": os.path.join(OBSIDIAN_BASE, "MyVault"),
        "vault": "personal",
        "area": "life",
        "tags": "[daily, personal]",
        "daily_root": "50-Notes",
    },
    {
        "vault_path": os.path.join(OBSIDIAN_BASE, "WorkVault"),
        "vault": "work",
        "area": "work",
        "tags": "[daily, work]",
        "daily_root": "50-Notes",
    },
]

DATE_FILE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}\.md$")
FRONTMATTER_RE = re.compile(r"^---\n.*?\n---\n?", re.DOTALL)


def build_frontmatter(date_str: str, vault: str, area: str, tags: str) -> str:
    return f"""---
title: "{date_str}"
type: daily-note
vault: {vault}
area: {area}
tags: {tags}
---
"""


def process_file(path: Path, vault: str, area: str, tags: str, dry_run: bool) -> bool:
    date_str = path.stem  # YYYY-MM-DD
    content = path.read_text(encoding="utf-8")

    # Strip existing frontmatter, preserve body
    body = FRONTMATTER_RE.sub("", content).lstrip("\n")
    new_content = build_frontmatter(date_str, vault, area, tags) + "\n" + body

    if new_content == content:
        return False  # already correct, nothing to do

    if not dry_run:
        path.write_text(new_content, encoding="utf-8")
    return True


def main():
    parser = argparse.ArgumentParser(description="Backfill daily note frontmatter")
    parser.add_argument("--dry-run", action="store_true", help="Preview without writing")
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO, format="%(message)s")
    log = logging.getLogger(__name__)

    if args.dry_run:
        log.info("DRY RUN — no files will be modified\n")

    for config in VAULT_CONFIG:
        daily_root = Path(config["vault_path"]) / config["daily_root"]
        vault_name = config["vault"]
        updated = skipped = 0

        for md_file in sorted(daily_root.rglob("*.md")):
            if not DATE_FILE_RE.match(md_file.name):
                continue
            changed = process_file(
                md_file, config["vault"], config["area"], config["tags"], args.dry_run
            )
            if changed:
                log.info(f"  {'[dry] ' if args.dry_run else ''}updated: {md_file.relative_to(Path(config['vault_path']))}")
                updated += 1
            else:
                skipped += 1

        log.info(f"{vault_name}: {updated} updated, {skipped} already correct\n")


if __name__ == "__main__":
    main()
