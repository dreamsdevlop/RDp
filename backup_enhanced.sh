#!/bin/bash
# ============================================
# 💾 Enhanced Smart Data Backup System
# Multi-target sync with GitHub Cache + Cloud Storage
# ============================================

set -e

# Configuration
LOCAL_DIR="/tmp/windows-storage/data"
GITHUB_CACHE_DIR="/tmp/github-cache"
REMOTE_NAME="remote"
REMOTE_DIR="rdp-backup"
SYNC_INTERVAL=600 # 10 minutes
LOG_FILE="/var/log/backup_enhanced.log"
METRICS_FILE="/tmp/backup_metrics.json"

# Ensure directories exist
mkdir -p "$LOCAL_DIR" "$GITHUB_CACHE_DIR"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Metrics tracking
update_metrics() {
    local status="$1"
    local last_sync="$2"
    local storage_used="$3"
    
    cat > "$METRICS_FILE" << EOF
{
    "status": "$status",
    "last_sync": "$last_sync",
    "storage_used_gb": $storage_used,
    "timestamp": "$(date -Iseconds)"
}
EOF
}

log "=== 💾 Starting Enhanced Backup Service ==="

# Check if Rclone config exists
if [ ! -f "$HOME/.config/rclone/rclone.conf" ]; then
    log "⚠️  No rclone.conf found. Cloud backup disabled."
    CLOUD_ENABLED=false
else
    CLOUD_ENABLED=true
    log "✅ Cloud backup enabled"
fi

# 1. GITHUB CACHE RESTORE PHASE
log "=== 📥 Restoring from GitHub Cache... ==="
if [ -d "$GITHUB_CACHE_DIR" ] && [ "$(ls -A $GITHUB_CACHE_DIR 2>/dev/null)" ]; then
    log "✅ GitHub cache found. Restoring..."
    rsync -av --progress "$GITHUB_CACHE_DIR/" "$LOCAL_DIR/" || log "⚠️  Cache restore failed, continuing..."
    log "✅ GitHub cache restore complete!"
else
    log "ℹ️  No GitHub cache found (or empty). Starting fresh."
fi

# 2. CLOUD BACKUP RESTORE PHASE
if [ "$CLOUD_ENABLED" = true ]; then
    log "=== 📥 Checking for cloud backup... ==="
    if rclone lsd "$REMOTE_NAME:$REMOTE_DIR" >/dev/null 2>&1; then
        log "✅ Cloud backup found. Restoring..."
        rclone copy "$REMOTE_NAME:$REMOTE_DIR" "$LOCAL_DIR" --progress || log "⚠️  Cloud restore failed, continuing..."
        log "✅ Cloud restore complete!"
    else
        log "ℹ️  No cloud backup found (or remote empty). Starting fresh."
    fi
fi

# 3. BACKUP LOOP WITH MULTI-TARGET SYNC
log "=== 🔄 Starting Enhanced Backup Loop (Every ${SYNC_INTERVAL}s) ==="

while true; do
    sleep "$SYNC_INTERVAL"
    
    log "=== 📤 Starting Multi-Target Sync... ==="
    
    # Calculate storage metrics
    STORAGE_USED=$(du -s "$LOCAL_DIR" 2>/dev/null | awk '{print $1/1024/1024}' || echo "0")
    
    # Sync to GitHub Cache
    log "📦 Syncing to GitHub Cache..."
    rsync -av --delete "$LOCAL_DIR/" "$GITHUB_CACHE_DIR/" || log "⚠️  GitHub cache sync failed"
    
    # Sync to Cloud Storage (if enabled)
    if [ "$CLOUD_ENABLED" = true ]; then
        log "☁️  Syncing to Cloud Storage..."
        if rclone sync "$LOCAL_DIR" "$REMOTE_NAME:$REMOTE_DIR" --progress --transfers 4 --checkers 8; then
            log "✅ Cloud sync successful"
            update_metrics "healthy" "$(date -Iseconds)" "$STORAGE_USED"
        else
            log "⚠️  Cloud sync failed"
            update_metrics "cloud_error" "$(date -Iseconds)" "$STORAGE_USED"
        fi
    else
        update_metrics "cache_only" "$(date -Iseconds)" "$STORAGE_USED"
    fi
    
    log "✅ Multi-target sync complete at $(date)"
done
