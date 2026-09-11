# fabric/patterns

Custom fabric patterns for this dev environment.

## How it works

`fabric/install.sh` symlinks any `.md` file in this directory into
`~/.config/fabric/patterns/` so fabric can find them.

## Adding a pattern

1. Create `patterns/my-pattern-name.md`
2. Write a `# SYSTEM` section and optionally a `# USER` section
3. Run `fabric/install.sh` to link it
4. Use: `fabric -p my-pattern-name`

## Default patterns

Fabric ships with hundreds of patterns from Daniel Miessler's repo.
Run `fabric --updatepatterns` to pull the latest.

Useful defaults in the context of this dev-env:
- `summarize` — summarise any content
- `extract_wisdom` — extract key insights from a transcript or article
- `create_summary` — structured summary with bullets
- `write_essay` — write an essay from bullet points

## See also

`llm/templates/` — lighter-weight prompt templates used by `llm/run.sh`
