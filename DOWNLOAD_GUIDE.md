# 📥 Download Best Practices

## Issue
Downloading large files through **Cloudflare Tunnel** can cause session disconnects because:
- Cloudflare free tunnels have bandwidth limits
- Long-running connections may timeout
- Network saturation can cause RDP to freeze

## ✅ Solution: Use Tailscale for Downloads

### Why Tailscale?
- **Direct connection** (no tunnel overhead)
- **No bandwidth limits**
- **More stable** for large transfers
- **Faster speeds**

### How to Use:
1. Connect to RDP via **Tailscale IP** instead of Cloudflare:
   ```
   Tailscale IP: <shown in deployment logs>:3389
   ```

2. Use your **native RDP client**:
   - **Windows**: Remote Desktop Connection
   - **Mac**: Microsoft Remote Desktop
   - **Linux**: Remmina

3. **Cloudflare is still useful for**:
   - Quick access from any device
   - Web-based NoVNC console
   - Initial setup

## Alternative: Download to Shared Storage
If you must use Cloudflare:
1. Download files to `C:\storage\data` inside Windows
2. They'll be backed up via Rclone (if configured)
3. Access them later from your cloud storage

## Performance Tips
- For files > 100MB, always use Tailscale
- For quick browsing, Cloudflare is fine
- Enable Rclone backup for important downloads
