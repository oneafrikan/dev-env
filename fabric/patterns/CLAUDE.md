# CLAUDE.md — fabric/patterns/

## Purpose

Custom fabric patterns for this dev environment. Each .md file is a pattern with a `# SYSTEM` section.

## Usage

Run `fabric/install.sh` to symlink patterns into `~/.config/fabric/patterns/`.
Then use: `fabric -p pattern-name`

## Adding patterns

Create `pattern-name.md` with at minimum:
```
# SYSTEM
Your system prompt here.
```
