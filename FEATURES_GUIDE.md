# 🚀 Enhanced 24/7 RDP Features Guide

This guide documents the new features added to the 24/7 Windows RDP project: **Persistent Storage**, **Multiple Users**, and **Monitoring Dashboard**.

## 📁 New Files Structure

```
.
├── backup_enhanced.sh              # Enhanced backup with multi-target sync
├── user_management/
│   ├── users.json                  # User database (JSON-based)
│   └── user_manager.sh             # User management script
├── dashboard/
│   ├── server.js                   # Node.js dashboard server
│   ├── alerts.js                   # Alert notification system
│   ├── package.json                # Dashboard dependencies
│   └── public/
│       └── index.html              # Web interface
└── FEATURES_GUIDE.md              # This file
```

## 🗄️ Phase 1: Persistent Storage System

### Overview
The enhanced backup system provides multi-layer persistent storage that survives container restarts and workflow timeouts.

### Features
- ✅ **GitHub Actions Cache**: Primary storage layer (10GB limit)
- ✅ **Cloud Storage**: Secondary backup via Rclone (Google Drive, Dropbox, etc.)
- ✅ **Smart Sync**: Automatic backup/restore on container start/stop
- ✅ **Storage Health**: Real-time usage monitoring and alerts

### Configuration

#### Enhanced Backup Script (`backup_enhanced.sh`)
```bash
# Configuration variables
LOCAL_DIR="/tmp/windows-storage/data"     # Local storage directory
GITHUB_CACHE_DIR="/tmp/github-cache"      # GitHub cache directory
REMOTE_NAME="remote"                      # Rclone remote name
REMOTE_DIR="rdp-backup"                   # Remote directory
SYNC_INTERVAL=600                         # Sync interval (10 minutes)
```

#### GitHub Actions Integration
```yaml
# In .github/workflows/rdp-24-7.yml
- name: 💾 Restore Persistent Storage
  id: storage-cache
  uses: actions/cache@v3
  with:
    path: /tmp/github-cache
    key: rdp-storage-${{ github.run_id }}
    restore-keys: |
      rdp-storage-
```

### Usage
```bash
# Start enhanced backup service
sudo bash backup_enhanced.sh

# The service will:
# 1. Restore from GitHub cache on startup
# 2. Restore from cloud storage if available
# 3. Sync to both targets every 10 minutes
# 4. Monitor storage health and send alerts
```

## 👥 Phase 2: Multiple User Management

### Overview
Dynamic user management system with role-based access control and profile isolation.

### Features
- ✅ **JSON-based User Database**: Easy user management
- ✅ **Dynamic User Creation**: Create users on container startup
- ✅ **Role-based Access**: Admin and user roles
- ✅ **Profile Isolation**: Separate storage and settings per user
- ✅ **Password Policy**: Configurable password requirements

### User Database Structure (`user_management/users.json`)

```json
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
```

### User Management Commands (`user_management/user_manager.sh`)

```bash
# Add a new user
sudo bash user_management/user_manager.sh add username password [role]

# List all users
sudo bash user_management/user_manager.sh list

# Delete a user
sudo bash user_management/user_manager.sh delete username

# Update user password
sudo bash user_management/user_manager.sh update-password username new_password

# Initialize all users (run on container startup)
sudo bash user_management/user_manager.sh init
```

### Example Usage
```bash
# Add admin user
sudo bash user_management/user_manager.sh add john securePass123 admin

# Add regular user
sudo bash user_management/user_manager.sh add jane userPass456 user

# List users
sudo bash user_management/user_manager.sh list
# Output:
# Username    | Role   | Enabled | Quota (GB) | Last Login
# ------------|--------|---------|------------|-----------
# MASTER      | admin  | true    | 10         | Never
# john        | admin  | true    | 5          | Never
# jane        | user   | true    | 5          | Never
```

## 📊 Phase 3: Real-time Monitoring Dashboard

### Overview
Comprehensive web-based monitoring dashboard with real-time metrics, alerts, and historical data.

### Features
- ✅ **Real-time Metrics**: Docker, Cloudflare, Tailscale, Storage monitoring
- ✅ **Alert System**: Email, Slack, and webhook notifications
- ✅ **Historical Data**: Performance tracking and trend analysis
- ✅ **WebSocket Updates**: Live dashboard updates every 30 seconds
- ✅ **RESTful API**: Programmatic access to all metrics

### Dashboard Components

#### Server (`dashboard/server.js`)
- Express.js web server
- WebSocket for real-time updates
- Metrics collection from system processes
- Alert system integration
- Historical data logging

#### Web Interface (`dashboard/public/index.html`)
- Responsive design
- Real-time system health display
- Backup status monitoring
- Connection information
- System logs viewer

#### Alert System (`dashboard/alerts.js`)
- Configurable alert rules
- Multiple notification channels
- Alert history and management
- Cooldown periods to prevent spam

### Installation

#### 1. Install Dependencies
```bash
cd dashboard
npm install
```

#### 2. Start Dashboard
```bash
# Production mode
npm start

# Development mode (with auto-restart)
npm run dev
```

#### 3. Access Dashboard
Open your browser and navigate to:
- **Local**: `http://localhost:3000`
- **GitHub Actions**: `https://xxx.trycloudflare.com` (when integrated)

### Dashboard API Endpoints

```bash
# Get current metrics
GET /api/metrics

# Get system health
GET /api/health

# Get system logs
GET /api/logs

# Get alerts
GET /api/alerts

# Acknowledge alert
POST /api/alerts/acknowledge/:id

# Get historical data
GET /api/history
```

### Alert Configuration (`dashboard/config.json`)

```json
{
  "alerts": {
    "docker_down": { "enabled": true, "cooldown": 300 },
    "cloudflare_down": { "enabled": true, "cooldown": 300 },
    "tailscale_down": { "enabled": true, "cooldown": 300 },
    "storage_full": { "enabled": true, "threshold": 90 },
    "backup_failed": { "enabled": true, "cooldown": 600 }
  },
  "notifications": {
    "email": { "enabled": false, "smtp": {}, "recipients": [] },
    "slack": { "enabled": false, "webhook_url": "" },
    "webhook": { "enabled": false, "url": "" }
  }
}
```

## 🔧 Integration with Existing System

### Enhanced RDP Script Integration

To integrate the new features with the existing `rdp.sh` script:

```bash
# Add to rdp.sh after Windows container starts

echo "=== 🔄 Starting Enhanced Backup Service ==="
sudo bash backup_enhanced.sh &

echo "=== 👥 Initializing User Management ==="
sudo bash user_management/user_manager.sh init &

echo "=== 📊 Starting Monitoring Dashboard ==="
cd /root/dockercom/dashboard
npm start &
```

### GitHub Actions Workflow Integration

The workflow already includes:
- GitHub cache for persistent storage
- Enhanced backup service startup
- User management initialization

## 🚀 Deployment Guide

### 1. Local/VPS Deployment

```bash
# 1. Make scripts executable
chmod +x rdp.sh backup_enhanced.sh user_management/user_manager.sh

# 2. Start RDP with enhanced features
sudo bash rdp.sh

# 3. Initialize users
sudo bash user_management/user_manager.sh init

# 4. Start dashboard
cd dashboard && npm start
```

### 2. GitHub Actions Deployment

```bash
# 1. Push to repository
git add .
git commit -m "Add enhanced features"
git push origin main

# 2. Enable GitHub Actions in repository settings
# 3. Start the workflow manually or wait for cron schedule
# 4. Check workflow output for access URLs
```

## 📈 Monitoring and Maintenance

### Dashboard Monitoring
- **Real-time Status**: Monitor system health every 30 seconds
- **Alert Notifications**: Get notified of issues via email/Slack
- **Historical Trends**: Track performance over time
- **Log Analysis**: View system logs in real-time

### Storage Management
- **Usage Monitoring**: Track storage consumption
- **Backup Verification**: Ensure backups are successful
- **Cache Management**: Monitor GitHub cache usage
- **Quota Management**: Track user storage quotas

### User Management
- **User Activity**: Monitor user logins and activity
- **Security**: Enforce password policies
- **Access Control**: Manage user permissions
- **Profile Management**: Handle user profiles and isolation

## 🔒 Security Considerations

### Password Security
- Use strong passwords (8+ characters, uppercase, numbers)
- Change default MASTER password
- Regular password rotation
- Consider encrypted password storage for production

### Network Security
- Use Tailscale VPN for secure access
- Monitor connection logs
- Implement rate limiting if needed
- Regular security updates

### Data Security
- Regular backup verification
- Encrypted cloud storage
- Access control for sensitive data
- Audit trail for data access

## 🐛 Troubleshooting

### Common Issues

#### Dashboard Not Starting
```bash
# Check if port 3000 is available
sudo netstat -tlnp | grep 3000

# Check Node.js installation
node --version
npm --version

# Check dependencies
cd dashboard && npm install
```

#### Backup Not Working
```bash
# Check Rclone configuration
rclone config show

# Test cloud connection
rclone ls remote:

# Check backup logs
tail -f /var/log/backup_enhanced.log
```

#### User Creation Failed
```bash
# Check Windows container status
sudo docker ps

# Check user manager logs
tail -f /var/log/user_manager.log

# Verify user database
cat user_management/users.json
```

#### Alerts Not Sending
```bash
# Check alert configuration
cat dashboard/config.json

# Test notification channels
# - Email: Check SMTP settings
# - Slack: Test webhook URL
# - Webhook: Verify endpoint
```

### Log Locations
- **Enhanced Backup**: `/var/log/backup_enhanced.log`
- **User Manager**: `/var/log/user_manager.log`
- **Dashboard**: Console output (stdout)
- **Windows Container**: `sudo docker logs windows`

## 📋 Future Enhancements

### Planned Features
- [ ] Encrypted password storage
- [ ] User session management
- [ ] Advanced backup scheduling
- [ ] Mobile dashboard interface
- [ ] Performance optimization
- [ ] Integration with external monitoring services

### Customization Options
- Custom alert thresholds
- Dashboard theme customization
- Additional notification channels
- Custom user roles and permissions
- Advanced storage quota management

## 🤝 Contributing

To contribute to the enhanced features:

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature-name`
3. **Make changes**: Add new features or fix issues
4. **Test thoroughly**: Ensure compatibility with existing features
5. **Submit PR**: Describe changes and benefits

## 📞 Support

For issues, questions, or feature requests:

1. **Check the troubleshooting section** above
2. **Review logs** for error messages
3. **Search existing issues** in the repository
4. **Create a new issue** with detailed information

---

**🎉 Your 24/7 RDP server now has enterprise-grade features!**

- **Persistent Storage**: Never lose data between restarts
- **Multiple Users**: Support for teams and role-based access
- **Monitoring Dashboard**: Complete visibility into system health
- **Alert System**: Proactive issue detection and notification

Enjoy your enhanced RDP experience! 🚀
