#!/bin/bash

# Source and destination paths
SOURCE="/Users/you/Obsidian/MyVault/"
DESTINATION="/Users/you/Library/CloudStorage/GoogleDrive-you@example.com/My Drive/ObsidianShadow/"
BACKUP_DIR="/Users/you/Library/CloudStorage/GoogleDrive-you@example.com/My Drive/ObsidianBackups/"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Get current date and time for the backup filename
DATETIME=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILENAME="ObsidianBrain_$DATETIME.zip"

# Display start message
echo "Starting Obsidian sync and backup process..."

# Sync using rsync
# -a: archive mode (preserves permissions, timestamps, etc.)
# -v: verbose output
# -z: compress data during transfer
# --delete: delete files in destination that are not in source
# --prune-empty-dirs: remove empty directories from destination
# --exclude: exclude specific files/directories

rsync -avz --delete --prune-empty-dirs \
  --exclude=".DS_Store" \
  --exclude=".trash/" \
  --exclude=".obsidian/workspace.json" \
  "$SOURCE" "$DESTINATION"

# Check if rsync was successful
if [ $? -eq 0 ]; then
    echo "Rsync completed successfully."
    
    # Create zip backup
    echo "Creating backup: $BACKUP_FILENAME"
    cd "$(dirname "$SOURCE")"
    zip -r "$BACKUP_DIR$BACKUP_FILENAME" "$(basename "$SOURCE")" -x "*.DS_Store" "*.trash/*" "*.obsidian/workspace.json"
    
    if [ $? -eq 0 ]; then
        echo "Backup completed successfully."
        echo "Backup saved to: $BACKUP_DIR$BACKUP_FILENAME"
    else
        echo "Error: Backup creation failed."
    fi
else
    echo "Error: Rsync process failed."
fi

echo "Process completed at $(date)"