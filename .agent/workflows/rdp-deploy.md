---
description: Deploy RDP using rdp.sh script
---

# RDP Deployment Workflow

This workflow runs the RDP deployment script with the necessary commands.

## Deployment Options

### Option 1: Local/VPS Deployment

// turbo-all

1. Switch to root user
```bash
sudo su
```

2. Execute the RDP setup script
```bash
bash rdp.sh
```

3. Start Tailscale daemon in background
```bash
sudo tailscaled --state=/var/lib/tailscale/tailscaled.state &
```

### Option 2: 24/7 GitHub Actions Deployment (Recommended)

For continuous 24/7 operation, use GitHub Actions:

1. Push your code to GitHub
```bash
git add .
git commit -m "Setup 24/7 RDP"
git push origin main
```

2. Enable GitHub Actions in repository settings

3. Manually trigger workflow or wait for auto-start:
   - Go to Actions tab → "24/7 Live RDP" → "Run workflow"
   - Or push to main branch to auto-trigger

4. Get access URLs from workflow output (wait 2-3 minutes)

## Notes

### Local Deployment
- Ensure you have sudo privileges before running this workflow
- The Tailscale daemon will run in the background to maintain the VPN connection
- Make sure `rdp.sh` is executable (`chmod +x rdp.sh` if needed)

### GitHub Actions Deployment
- Free 24/7 hosting on GitHub Actions
- Auto-restarts every 5 hours to maintain uptime
- Public access via Cloudflare Tunnel (no port forwarding)
- See README.md for detailed setup instructions
