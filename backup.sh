#!/bin/bash
# ============================================
# 💾 Smart Data Backup (Rclone)
# Syncs /tmp/windows-storage/data to Cloud Storage
# ============================================

# Configuration
LOCAL_DIR="/tmp/windows-storage/data"
REMOTE_NAME="remote" # Matches the name in rclone.conf
REMOTE_DIR="rdp-backup"
SYNC_INTERVAL=600 # 10 minutes

# Ensure local directory exists
mkdir -p "$LOCAL_DIR"

echo "=== 💾 Starting Smart Backup Service ==="

# Check if Rclone config exists
if [ ! -f "$HOME/.config/rclone/rclone.conf" ]; then
    echo "⚠️  No rclone.conf found. Skipping backup service."
    echo "    Add RCLONE_CONFIG secret to enable."
    exit 0
fi

# 1. RESTORE PHASE
echo "=== 📥 Checking for existing backup... ==="
if rclone lsd "$REMOTE_NAME:$REMOTE_DIR" >/dev/null 2>&1; then
    echo "✅ Backup found. Restoring..."
    rclone copy "$REMOTE_NAME:$REMOTE_DIR" "$LOCAL_DIR" --progress
    echo "✅ Restore complete!"
else
    echo "ℹ️  No backup found (or remote empty). Starting fresh."
fi

# 2. BACKUP LOOP
echo "=== 🔄 Starting Backup Loop (Every ${SYNC_INTERVAL}s) ==="
while true; do
    sleep "$SYNC_INTERVAL"
    echo "=== 📤 Syncing data to cloud... ==="
    # Sync local to remote (one-way sync)
    rclone sync "$LOCAL_DIR" "$REMOTE_NAME:$REMOTE_DIR" --progress
    echo "✅ Sync complete at $(date)"
done
