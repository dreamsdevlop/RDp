# 🔐 Persistent RDP Setup Guide

## Your Setup
- **Tailscale IP**: `100.91.158.105:3389` (stays the same across all workflow runs)
- **Credentials**: `MASTER` / `admin@123`

## ✅ What's Already Working
1. **Same IP Every Time** - Tailscale state is cached, so `100.91.158.105` persists
2. **Auto-Reconnect** - Workflow triggers every 5 hours to maintain 24/7 uptime

## 💾 Enable Data Persistence (IMPORTANT!)

To keep your files, downloads, and settings between workflow runs, you MUST set up Rclone:

### Step 1: Generate Rclone Config
On your local computer:
```bash
# Install rclone
curl https://rclone.org/install.sh | sudo bash

# Configure it
rclone config
```

Follow the prompts:
1. Choose `n` for new remote
2. Name it: `remote`
3. Select your cloud provider (Google Drive recommended)
4. Follow authentication steps

### Step 2: Get Config Content
```bash
rclone config show
```
Copy the entire output (from `[remote]` to the end)

### Step 3: Add to GitHub Secrets
1. Go to: https://github.com/dreamsdevlop/RDp/settings/secrets/actions
2. Click **New repository secret**
3. Name: `RCLONE_CONFIG`
4. Value: Paste the config you copied
5. Click **Add secret**

### Step 4: Save Files to the Right Location
Inside Windows RDP:
- **Save important files to**: `C:\storage\data`
- This folder is automatically backed up every 10 minutes
- On next workflow run, files are restored automatically

## 📊 How It Works

```
Workflow Run #1:
├─ Tailscale connects → 100.91.158.105
├─ Windows boots
├─ Rclone restores files from cloud
└─ You work, download files to C:\storage\data

Every 10 minutes:
└─ Rclone syncs C:\storage\data to cloud

Workflow Run #2 (5 hours later):
├─ Tailscale connects → 100.91.158.105 (SAME IP!)
├─ Windows boots
├─ Rclone restores your files
└─ Your downloads/files are back!
```

## 🎯 Quick Start Checklist
- [x] Tailscale IP is persistent (`100.91.158.105`)
- [ ] Set up `RCLONE_CONFIG` secret
- [ ] Save files to `C:\storage\data`
- [ ] Test: Download a file, wait for next run, verify it's restored

## 💡 Pro Tips
1. **For 40GB+ downloads**: Use Tailscale RDP (not Cloudflare)
2. **Bookmark your connection**: `100.91.158.105:3389` in your RDP client
3. **Check backup status**: Files in `C:\storage\data` are auto-backed up
4. **Monitor workflow**: https://github.com/dreamsdevlop/RDp/actions

## ⚠️ Important Notes
- Without Rclone, files are lost every 5 hours (when workflow restarts)
- With Rclone, files persist forever in your cloud storage
- The Tailscale IP stays the same regardless of Rclone setup
