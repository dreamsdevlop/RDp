# 🚀 24/7 Live RDP on GitHub Actions

This repository provides a fully automated Windows 11 RDP server running 24/7 on GitHub Actions with Cloudflare Tunnel for public access.

## ✨ Features

- ✅ **Windows 11** running in Docker container
- ✅ **24/7 Uptime** with auto-restart every 5 hours
- ✅ **Public Access** via Cloudflare Tunnel (no port forwarding needed)
- ✅ **Web Console** (NoVNC) for browser-based access
- ✅ **RDP Access** for native Remote Desktop clients
- ✅ **Auto Health Checks** to restart failed services
- ✅ **Free** - runs on GitHub Actions free tier

## 🎯 Quick Start

### 1. Enable GitHub Actions

1. Go to your repository **Settings** → **Actions** → **General**
2. Under "Actions permissions", select **"Allow all actions and reusable workflows"**
3. Click **Save**

### 2. Start the RDP Server

**Option A: Manual Start**
1. Go to **Actions** tab in your repository
2. Click on **"24/7 Live RDP"** workflow
3. Click **"Run workflow"** → **"Run workflow"**

**Option B: Auto-Start (Recommended)**
- The workflow automatically starts every 5 hours via cron schedule
- Simply push to `main` or `master` branch to trigger it

### 3. Get Access URLs

1. Click on the running workflow
2. Wait 2-3 minutes for initialization
3. Check the **"Display Access Information"** step for your URLs:
   - **Web Console**: `https://xxx.trycloudflare.com`
   - **RDP Access**: `tcp://xxx.trycloudflare.com:xxxxx`

### 4. Connect to RDP

**Default Credentials:**
- **Username**: `MASTER`
- **Password**: `admin@123`

**Windows/Mac RDP Client:**
```
Host: xxx.trycloudflare.com:xxxxx
Username: MASTER
Password: admin@123
```

**Web Browser:**
Just open the Web Console URL in your browser!

## 🔧 Configuration

### Modify Resources

Edit `rdp.sh` to change VM resources:

```bash
RAM_SIZE: "7G"      # Change RAM allocation
CPU_CORES: "4"      # Change CPU cores
VERSION: "11"       # Windows version (10, 11, etc.)
```

### Change Credentials

Edit `rdp.sh`:

```bash
USERNAME: "MASTER"      # Your username
PASSWORD: "admin@123"   # Your password
```

### Adjust Runtime

Edit `.github/workflows/rdp-24-7.yml`:

```yaml
timeout-minutes: 350  # Maximum 360 (6 hours)
```

## 📊 Monitoring

### Check Status

1. Go to **Actions** tab
2. Click on the running workflow
3. View real-time logs in **"Keep Alive"** step

### View Logs

The workflow displays:
- Docker container status
- Cloudflare tunnel URLs
- Health check results
- Time remaining in current session

## 🔄 How 24/7 Works

1. **Workflow runs for ~5.5 hours** (GitHub's 6-hour limit)
2. **Cron schedule triggers new workflow** every 5 hours
3. **Overlapping execution** ensures no downtime
4. **Health checks** restart failed services automatically

## ⚠️ Important Notes

### GitHub Actions Limits

- **Free tier**: 2,000 minutes/month for private repos (unlimited for public)
- **Concurrent jobs**: 20 for free tier
- **Job timeout**: 6 hours maximum
- **Storage**: 500 MB for artifacts

### Cloudflare Tunnel Limits

- **Free tier**: Unlimited bandwidth
- **URL changes**: New URL every workflow restart (~5 hours)
- **Connection**: No authentication required

### Performance

- **KVM**: Not available on GitHub runners (slower performance)
- **RAM**: 7GB allocated (GitHub runners have 7GB total)
- **CPU**: 4 cores (GitHub runners have 2-4 cores)
- **Disk**: Uses runner's temporary storage

## 🛠️ Troubleshooting

### Workflow Not Starting

1. Check Actions are enabled in repository settings
2. Verify workflow file is in `.github/workflows/`
3. Check branch name matches trigger (`main` or `master`)

### Can't Connect to RDP

1. Wait 2-3 minutes after workflow starts
2. Check "Display Access Information" for correct URLs
3. Verify Cloudflare tunnel logs in workflow output
4. Try web console first (easier to debug)

### Container Keeps Restarting

1. Check Docker logs in workflow output
2. Reduce RAM_SIZE if out of memory
3. Reduce CPU_CORES if overloaded

### URL Changes Too Often

- This is normal - Cloudflare free tunnels change every session
- Consider using Cloudflare Tunnel with a custom domain (requires paid plan)
- Or use ngrok/tailscale for persistent URLs

## 🚀 Advanced Usage

### Use Custom Domain

Replace Cloudflare Tunnel section in `rdp.sh` with:

```bash
# Requires Cloudflare account and domain
cloudflared tunnel --hostname rdp.yourdomain.com --url tcp://localhost:3389
```

### Add Tailscale VPN

The script already includes Tailscale support:

```bash
sudo tailscaled --state=/var/lib/tailscale/tailscaled.state &
sudo tailscale up --authkey=YOUR_AUTH_KEY
```

### Persistent Storage

Add GitHub Actions cache:

```yaml
- name: Cache Windows Storage
  uses: actions/cache@v3
  with:
    path: /tmp/windows-storage
    key: windows-storage-${{ github.run_id }}
    restore-keys: windows-storage-
```

## 📝 Files Structure

```
.
├── .github/
│   └── workflows/
│       └── rdp-24-7.yml          # GitHub Actions workflow
├── .agent/
│   └── workflows/
│       └── rdp-deploy.md         # Local deployment workflow
├── rdp.sh                        # Main RDP setup script
├── rdp.ps1                       # PowerShell version
├── deploy_gcp.sh                 # GCP deployment script
└── README.md                     # This file
```

## 🤝 Contributing

Feel free to submit issues and pull requests!

## 📄 License

This project is open source and available under the MIT License.

## ⚡ Credits

- **dockurr/windows**: Docker Windows container
- **Cloudflare Tunnel**: Free public access
- **GitHub Actions**: Free CI/CD platform

---

**Made with ❤️ for 24/7 free RDP access**
