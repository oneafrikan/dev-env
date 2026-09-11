#!/bin/bash

# Usage: bash sync_obsidian_V2.sh [/path/to/vault]

# Source and destination paths
DEFAULT_VAULT="/Users/you/Obsidian/MyVault"
SOURCE="${1:-$DEFAULT_VAULT}"
SOURCE="${SOURCE%/}/"  # Normalize: strip then re-add trailing slash
VAULT_NAME=$(basename "${SOURCE%/}")

GDRIVE_BASE="/Users/you/Library/CloudStorage/GoogleDrive-you@example.com/My Drive/"
BACKUP_DIR="${GDRIVE_BASE}ObsidianBackups/"
EXTRACT_DIR="${GDRIVE_BASE}ObsidianShadow/${VAULT_NAME}/"

# Validate source exists
if [ ! -d "$SOURCE" ]; then
    echo "Error: Vault not found: $SOURCE"
    exit 1
fi

# Create directories if they don't exist
mkdir -p "$BACKUP_DIR"
mkdir -p "$EXTRACT_DIR"

# Get current date and time for the backup filename
DATETIME=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILENAME="${VAULT_NAME}_$DATETIME.zip"
BACKUP_PATH="$BACKUP_DIR$BACKUP_FILENAME"

# Display start message
echo "Starting Obsidian backup process for: $VAULT_NAME"

# 1. Create zip backup with datetime
echo "Creating timestamped backup: $BACKUP_FILENAME"
cd "$(dirname "$SOURCE")"
zip -r "$BACKUP_PATH" "$(basename "${SOURCE%/}")" -x "*.DS_Store" "*.trash/*" "*.obsidian/workspace.json"

# Check if zip was successful
if [ $? -eq 0 ]; then
    echo "Zip backup created successfully at: $BACKUP_PATH"

    # 2. Upload step not needed as we're directly creating the zip in Google Drive path
    echo "Backup saved directly to Google Drive at: $BACKUP_PATH"

    # 3. Extract the zip to maintain the latest version
    echo "Extracting the backup to maintain the latest version..."

    # Clean the extract directory first to ensure no old files remain
    rm -rf "$EXTRACT_DIR"/*

    # Extract the zip file
    unzip -o "$BACKUP_PATH" -d "$EXTRACT_DIR"

    if [ $? -eq 0 ]; then
        echo "Extraction completed successfully."
        echo "Latest version available at: $EXTRACT_DIR"
    else
        echo "Error: Extraction failed."
    fi
else
    echo "Error: Zip backup creation failed."
fi

echo "Process completed at $(date)"
