# CLAUDE.md — data/

## Purpose

Data engineering utilities. Inspect, validate, and catalogue CSV/Parquet/DuckDB files.

## Conventions

- DuckDB is the universal query engine — all file inspection goes through it
- inspect.sh pipes output through LLM data-summary template
- catalogue.sh writes to ~/.dev-env-catalogue.db (gitignored)

## Dependencies

- `duckdb` — required for most scripts
- `jq` — schema validation in validate-export.sh
- `llm/run.sh` — AI data summaries

## Scripts

| Name               | Status      | Description                                   |
|--------------------|-------------|-----------------------------------------------|
| inspect.sh         | implemented | Inspect CSV/Parquet/DuckDB + AI summary       |
| freshness-check.sh | implemented | Report file ages, flag stale data             |
| validate-export.sh | implemented | Validate row count, nulls, schema, duplicates |
| catalogue.sh       | implemented | Catalogue all data files into DuckDB          |
| duckdb-session.sh  | stub        | Launch DuckDB with common setup               |
| query-run.sh       | stub        | Run a SQL query file against a dataset        |
| schema-diff.sh     | stub        | Diff schemas between two files                |
| pipeline-run.sh    | stub        | Run a named data pipeline                     |
| dir-monitor.sh     | stub        | Watch a directory for new files               |
| partition-check.sh | stub        | Verify partitioned dataset completeness       |

## Secrets

None — but some pipelines may need API keys in .env files.
