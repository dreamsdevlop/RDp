#!/bin/bash
# ============================================
# 👥 User Management System
# Dynamic user creation, management, and profile isolation
# ============================================

set -e

# Configuration
USERS_DB="/root/dockercom/user_management/users.json"
STORAGE_BASE="/tmp/windows-storage"
LOG_FILE="/var/log/user_manager.log"
OEM_DIR="/root/dockercom/oem"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Load users database
load_users() {
    if [ ! -f "$USERS_DB" ]; then
        log "⚠️  Users database not found, creating default"
        mkdir -p "$(dirname "$USERS_DB")"
        cat > "$USERS_DB" << 'EOF'
{
    "version": "1.0",
    "users": {
        "MASTER": {
            "password": "admin@123",
            "role": "admin",
            "profile_path": "/storage/users/MASTER",
            "created_at": "2024-01-01T00:00:00Z",
            "last_login": null,
            "enabled": true,
            "storage_quota_gb": 10
        }
    },
    "settings": {
        "default_role": "user",
        "default_quota_gb": 5,
        "max_users": 10,
        "password_policy": {
            "min_length": 8,
            "require_uppercase": true,
            "require_numbers": true,
            "require_special": false
        }
    }
}
EOF
    fi
    echo "$(cat "$USERS_DB")"
}

# Save users database
save_users() {
    local users_data="$1"
    echo "$users_data" > "$USERS_DB"
}

# Validate password
validate_password() {
    local password="$1"
    local policy=$(echo "$USERS_DB_CONTENT" | jq -r '.settings.password_policy')
    
    local min_length=$(echo "$policy" | jq -r '.min_length')
    local require_uppercase=$(echo "$policy" | jq -r '.require_uppercase')
    local require_numbers=$(echo "$policy" | jq -r '.require_numbers')
    local require_special=$(echo "$policy" | jq -r '.require_special')
    
    # Check length
    if [ ${#password} -lt "$min_length" ]; then
        log "❌ Password too short (minimum $min_length characters)"
        return 1
    fi
    
    # Check uppercase
    if [ "$require_uppercase" = "true" ] && ! [[ "$password" =~ [A-Z] ]]; then
        log "❌ Password must contain uppercase letters"
        return 1
    fi
    
    # Check numbers
    if [ "$require_numbers" = "true" ] && ! [[ "$password" =~ [0-9] ]]; then
        log "❌ Password must contain numbers"
        return 1
    fi
    
    # Check special characters
    if [ "$require_special" = "true" ] && ! [[ "$password" =~ [^a-zA-Z0-9] ]]; then
        log "❌ Password must contain special characters"
        return 1
    fi
    
    return 0
}

# Create user profile
create_user_profile() {
    local username="$1"
    local profile_path="$STORAGE_BASE/users/$username"
    
    log "📁 Creating profile for user $username at $profile_path"
    
    # Create user directory structure
    mkdir -p "$profile_path"/{Documents,Downloads,Pictures,Desktop}
    
    # Create user-specific startup script
    cat > "$OEM_DIR/user_${username}.bat" << EOF
@echo off
REM User-specific profile setup for $username
echo Setting up profile for $username...
mkdir "%USERPROFILE%\Documents"
mkdir "%USERPROFILE%\Downloads"
mkdir "%USERPROFILE%\Pictures"
mkdir "%USERPROFILE%\Desktop"
echo Profile setup complete for $username
EOF
    
    log "✅ User profile created for $username"
}

# Create Windows user
create_windows_user() {
    local username="$1"
    local password="$2"
    local role="$3"
    
    log "👤 Creating Windows user: $username (Role: $role)"
    
    # Create user via Docker exec
    docker exec windows cmd.exe /c "net user $username $password /add" || {
        log "⚠️  Failed to create user $username, may already exist"
        return 1
    }
    
    # Add to appropriate groups based on role
    if [ "$role" = "admin" ]; then
        docker exec windows cmd.exe /c "net localgroup administrators $username /add" || log "⚠️  Failed to add $username to administrators"
    else
        docker exec windows cmd.exe /c "net localgroup users $username /add" || log "⚠️  Failed to add $username to users"
    fi
    
    # Activate user
    docker exec windows cmd.exe /c "net user $username /active:yes" || log "⚠️  Failed to activate user $username"
    
    log "✅ Windows user $username created successfully"
}

# Add new user
add_user() {
    local username="$1"
    local password="$2"
    local role="$3"
    
    if [ -z "$username" ] || [ -z "$password" ]; then
        log "❌ Usage: add_user <username> <password> [role]"
        return 1
    fi
    
    role="${role:-user}"
    
    log "=== Adding new user: $username ==="
    
    # Load current users
    USERS_DB_CONTENT=$(load_users)
    
    # Check if user already exists
    if echo "$USERS_DB_CONTENT" | jq -e ".users.$username" >/dev/null 2>&1; then
        log "❌ User $username already exists"
        return 1
    fi
    
    # Validate password
    if ! validate_password "$password"; then
        return 1
    fi
    
    # Check user limit
    current_users=$(echo "$USERS_DB_CONTENT" | jq '.users | length')
    max_users=$(echo "$USERS_DB_CONTENT" | jq -r '.settings.max_users')
    
    if [ "$current_users" -ge "$max_users" ]; then
        log "❌ Maximum number of users ($max_users) reached"
        return 1
    fi
    
    # Create user entry
    local timestamp=$(date -Iseconds)
    local profile_path="/storage/users/$username"
    local quota=$(echo "$USERS_DB_CONTENT" | jq -r '.settings.default_quota_gb')
    
    # Add user to database
    USERS_DB_CONTENT=$(echo "$USERS_DB_CONTENT" | jq ".users += {
        \"$username\": {
            \"password\": \"$password\",
            \"role\": \"$role\",
            \"profile_path\": \"$profile_path\",
            \"created_at\": \"$timestamp\",
            \"last_login\": null,
            \"enabled\": true,
            \"storage_quota_gb\": $quota
        }
    }")
    
    # Save database
    save_users "$USERS_DB_CONTENT"
    
    # Create profile and Windows user
    create_user_profile "$username"
    create_windows_user "$username" "$password" "$role"
    
    log "✅ User $username added successfully"
}

# List all users
list_users() {
    log "=== Current Users ==="
    USERS_DB_CONTENT=$(load_users)
    
    echo "Username    | Role   | Enabled | Quota (GB) | Last Login"
    echo "------------|--------|---------|------------|-----------"
    
    echo "$USERS_DB_CONTENT" | jq -r '.users | to_entries[] | "\(.key)\t|\(.value.role)\t|\(.value.enabled)\t|\(.value.storage_quota_gb)\t|\(.value.last_login // "Never")"' | \
    while IFS=$'\t' read -r username role enabled quota last_login; do
        printf "%-10s | %-6s | %-7s | %-10s | %s\n" "$username" "$role" "$enabled" "$quota" "$last_login"
    done
}

# Delete user
delete_user() {
    local username="$1"
    
    if [ -z "$username" ]; then
        log "❌ Usage: delete_user <username>"
        return 1
    fi
    
    log "=== Deleting user: $username ==="
    
    USERS_DB_CONTENT=$(load_users)
    
    # Check if user exists
    if ! echo "$USERS_DB_CONTENT" | jq -e ".users.$username" >/dev/null 2>&1; then
        log "❌ User $username does not exist"
        return 1
    fi
    
    # Remove from Windows
    docker exec windows cmd.exe /c "net user $username /delete" || log "⚠️  Failed to delete Windows user $username"
    
    # Remove profile directory
    rm -rf "$STORAGE_BASE/users/$username"
    
    # Remove from database
    USERS_DB_CONTENT=$(echo "$USERS_DB_CONTENT" | jq "del(.users.$username)")
    save_users "$USERS_DB_CONTENT"
    
    log "✅ User $username deleted successfully"
}

# Update user password
update_password() {
    local username="$1"
    local new_password="$2"
    
    if [ -z "$username" ] || [ -z "$new_password" ]; then
        log "❌ Usage: update_password <username> <new_password>"
        return 1
    fi
    
    log "=== Updating password for user: $username ==="
    
    USERS_DB_CONTENT=$(load_users)
    
    # Check if user exists
    if ! echo "$USERS_DB_CONTENT" | jq -e ".users.$username" >/dev/null 2>&1; then
        log "❌ User $username does not exist"
        return 1
    fi
    
    # Validate new password
    if ! validate_password "$new_password"; then
        return 1
    fi
    
    # Update Windows password
    docker exec windows cmd.exe /c "net user $username $new_password" || {
        log "❌ Failed to update Windows password for $username"
        return 1
    }
    
    # Update database
    USERS_DB_CONTENT=$(echo "$USERS_DB_CONTENT" | jq ".users.$username.password = \"$new_password\"")
    save_users "$USERS_DB_CONTENT"
    
    log "✅ Password updated for user $username"
}

# Initialize all users
initialize_users() {
    log "=== Initializing User Management System ==="
    
    # Load users database
    USERS_DB_CONTENT=$(load_users)
    
    # Get all users
    local users=$(echo "$USERS_DB_CONTENT" | jq -r '.users | keys[]')
    
    for username in $users; do
        local user_data=$(echo "$USERS_DB_CONTENT" | jq -r ".users.$username")
        local password=$(echo "$user_data" | jq -r '.password')
        local role=$(echo "$user_data" | jq -r '.role')
        local enabled=$(echo "$user_data" | jq -r '.enabled')
        
        if [ "$enabled" = "true" ]; then
            log "👤 Processing user: $username (Role: $role)"
            
            # Create profile if it doesn't exist
            create_user_profile "$username"
            
            # Create Windows user if it doesn't exist
            if ! docker exec windows cmd.exe /c "net user $username" >/dev/null 2>&1; then
                create_windows_user "$username" "$password" "$role"
            else
                log "ℹ️  User $username already exists in Windows"
            fi
        fi
    done
    
    log "✅ User management initialization complete"
}

# Main script logic
case "${1:-}" in
    "add")
        add_user "$2" "$3" "$4"
        ;;
    "list")
        list_users
        ;;
    "delete")
        delete_user "$2"
        ;;
    "update-password")
        update_password "$2" "$3"
        ;;
    "init")
        initialize_users
        ;;
    *)
        echo "Usage: $0 {add|list|delete|update-password|init} [args...]"
        echo "  add <username> <password> [role]     - Add new user"
        echo "  list                               - List all users"
        echo "  delete <username>                  - Delete user"
        echo "  update-password <username> <new_password> - Update user password"
        echo "  init                               - Initialize all users"
        exit 1
        ;;
esac
