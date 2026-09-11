#!/bin/bash

# Usage:
#   bash run_all.sh                        # Process all vaults in vaults.conf
#   bash run_all.sh /path/to/vault         # Process a single vault

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONF="$SCRIPT_DIR/vaults.conf"

if [ -n "$1" ]; then
    VAULTS=("$1")
else
    if [ ! -f "$CONF" ]; then
        echo "Error: vaults.conf not found at $CONF"
        exit 1
    fi
    # Read vaults.conf, skip comments and blank lines (compatible with macOS bash 3.2)
    VAULTS=()
    while IFS= read -r line; do
        VAULTS+=("$line")
    done < <(grep -v '^\s*#' "$CONF" | grep -v '^\s*$')
fi

if [ ${#VAULTS[@]} -eq 0 ]; then
    echo "Error: No vaults configured. Check $CONF"
    exit 1
fi

FAILED=0

for VAULT in "${VAULTS[@]}"; do
    VAULT_NAME=$(basename "$VAULT")
    echo "=========================================="
    echo "Processing vault: $VAULT_NAME"
    echo "=========================================="

    if [ ! -d "$VAULT" ]; then
        echo "Error: Vault not found: $VAULT — skipping."
        FAILED=$((FAILED + 1))
        continue
    fi

    echo "--- Step 1: Cleaning stale indexes ---"
    python3 "$SCRIPT_DIR/clean_obsidian_index_files.py" "$VAULT" --delete

    echo "--- Step 2: Building indexes ---"
    python3 "$SCRIPT_DIR/build_obsidian_vault_index.py" "$VAULT"
    if [ $? -ne 0 ]; then
        echo "Error: Index generation failed for $VAULT_NAME. Skipping sync."
        FAILED=$((FAILED + 1))
        continue
    fi

    echo "--- Step 3: Backing up to Google Drive ---"
    bash "$SCRIPT_DIR/sync_obsidian_V2.sh" "$VAULT"
    if [ $? -ne 0 ]; then
        echo "Error: Backup failed for $VAULT_NAME."
        FAILED=$((FAILED + 1))
    fi

    echo ""
done

if [ $FAILED -gt 0 ]; then
    echo "$FAILED vault(s) had errors."
    exit 1
fi

echo "All vaults processed successfully."
