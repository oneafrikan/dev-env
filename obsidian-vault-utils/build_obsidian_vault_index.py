"""Generate Dataview-based index files for an Obsidian vault.

Recursively creates {folder-name}_INDEX.md files using Dataview TABLE queries
instead of wikilinks, so indexes remain navigable but don't create graph edges.

Usage:
    python3 build_obsidian_vault_index.py                          # Default vault
    python3 build_obsidian_vault_index.py /path/to/vault           # Specific vault
    python3 build_obsidian_vault_index.py /path/to/vault --max-depth 2
"""

import argparse
import os
from pathlib import Path
from datetime import datetime

DEFAULT_VAULT = "/Users/you/Obsidian/MyVault"

IGNORE_FOLDERS = {".trash", ".obsidian", ".claude"}
FOLDER_ICON = "\U0001F4C2"  # 📂
FILE_ICON = "\U0001F4C4"    # 📄

# === UTILITY ===
def format_line(depth: int, name: str, is_folder: bool) -> str:
    indent = "  " * depth
    icon = FOLDER_ICON if is_folder else FILE_ICON
    link = f"**{icon} {name}**" if is_folder else f"[[{name}]]"
    return f"{indent}- {link}"

def dataview_query(folder_relative: str) -> str:
    return (
        "```dataview\n"
        "TABLE WITHOUT ID file.link AS \"Note\", file.mtime AS \"Modified\"\n"
        f"FROM \"{folder_relative}\"\n"
        "WHERE file.name != this.file.name\n"
        "SORT file.name ASC\n"
        "```"
    )

def build_folder_index(folder_path: Path, vault_path: Path, max_depth: int = 4, current_depth: int = 0):
    relative_path = folder_path.relative_to(vault_path)
    folder_relative = str(relative_path).replace(os.sep, "/")
    lines = [f"# {FOLDER_ICON} {relative_path.name}\n"]

    # List subfolders with links to their index files
    subfolders = sorted(
        [item for item in folder_path.iterdir()
         if item.is_dir() and not item.name.startswith(".") and item.name not in IGNORE_FOLDERS],
        key=lambda x: x.name.lower()
    )

    if subfolders:
        lines.append("## Subfolders\n")
        for item in subfolders:
            lines.append(f"- {FOLDER_ICON} [[{item.name}/{item.name}_INDEX|{item.name}]]")
            if current_depth < max_depth:
                build_folder_index(item, vault_path, max_depth, current_depth + 1)
        lines.append("")

    # Dataview query for all notes in this folder
    lines.append("## Notes\n")
    lines.append(dataview_query(folder_relative))

    index_name = f"{relative_path.name}_INDEX.md"
    old_index = folder_path / "Index.md"
    new_index = folder_path / index_name
    if old_index.exists():
        old_index.rename(new_index)
    new_index.write_text("\n".join(lines))

def build_full_structure(vault_path: Path):
    full_structure_file = vault_path / "INDEX_Full_Structure.md"
    lines = ["---",
             "type: vault-structure",
             f"generated: {datetime.now().isoformat(timespec='seconds')}",
             "format: nested-markdown",
             "---\n"]

    def walk(path: Path, depth: int = 0):
        for item in sorted(path.iterdir(), key=lambda x: (x.is_file(), x.name.lower())):
            if item.name.startswith(".") or item.name in IGNORE_FOLDERS:
                continue
            if item.is_dir():
                lines.append(format_line(depth, item.name, True))
                walk(item, depth + 1)
            elif item.suffix == ".md":
                lines.append(format_line(depth, item.stem, False))

    walk(vault_path)
    full_structure_file.write_text("\n".join(lines))
    print(f"Full vault structure written to: {full_structure_file}")

def write_top_index(vault_path: Path):
    top_index_file = vault_path / "INDEX.md"
    top_lines = ["# \U0001F4DA Vault Index\n\n> Entry points into major folders. Auto-generated.\n"]

    for item in sorted(vault_path.iterdir(), key=lambda x: x.name.lower()):
        if item.is_dir() and item.name not in IGNORE_FOLDERS:
            top_lines.append(f"- {FOLDER_ICON} [[{item.name}/{item.name}_INDEX|{item.name}]]")
            build_folder_index(item, vault_path)

    top_index_file.write_text("\n".join(top_lines))
    print(f"Top-level vault index written to: {top_index_file}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate Dataview-based index files for an Obsidian vault."
    )
    parser.add_argument(
        "vault",
        nargs="?",
        default=DEFAULT_VAULT,
        help=f"Path to the vault (default: {DEFAULT_VAULT})",
    )
    parser.add_argument(
        "--max-depth",
        type=int,
        default=4,
        help="Maximum recursion depth for subfolder indexes (default: 4)",
    )
    args = parser.parse_args()

    vault_path = Path(args.vault).resolve()
    if not vault_path.is_dir():
        parser.error(f"Vault path does not exist: {vault_path}")

    write_top_index(vault_path)
    build_full_structure(vault_path)
