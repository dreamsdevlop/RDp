# 🔐 Tailscale VPN Setup Guide

This guide shows you how to enable Tailscale VPN access for your 24/7 RDP server on GitHub Actions.

## 🎯 What is Tailscale?

Tailscale creates a secure VPN network between your devices. Unlike Cloudflare tunnels (which give you a public URL that changes every 5 hours), Tailscale provides:

- ✅ **Private VPN access** - Only you can connect
- ✅ **Persistent IP** - Same IP across workflow restarts
- ✅ **Better performance** - Direct peer-to-peer connection
- ✅ **More secure** - Not publicly accessible
- ✅ **Free tier** - Up to 100 devices

## 📋 Setup Steps

### Step 1: Create Tailscale Account

1. Go to: **https://login.tailscale.com/start**
2. Sign up with Google, Microsoft, or GitHub
3. Complete the registration

### Step 2: Generate Auth Key

1. Go to: **https://login.tailscale.com/admin/settings/keys**
2. Click **"Generate auth key"**
3. Configure the key:
   - ✅ Check **"Reusable"** (important!)
   - ✅ Check **"Ephemeral"** (recommended - auto-cleanup)
   - Set expiration: **90 days** or longer
   - Add tag (optional): `tag:github-actions`
4. Click **"Generate key"**
5. **Copy the key** (starts with `tskey-auth-...`)

### Step 3: Add Key to GitHub Secrets

1. Go to your repository: **https://github.com/dreamsdevlop/RDp/settings/secrets/actions**
2. Click **"New repository secret"**
3. Name: `TAILSCALE_AUTH_KEY`
4. Value: Paste your auth key (e.g., `tskey-auth-xxxxxxxxxxxxx`)
5. Click **"Add secret"**

### Step 4: Run the Workflow

1. Go to: **https://github.com/dreamsdevlop/RDp/actions**
2. Click **"24/7 Live RDP"**
3. Click **"Run workflow"** → **"Run workflow"**
4. Wait 2-3 minutes for initialization

### Step 5: Install Tailscale on Your Device

#### Windows:
1. Download: **https://tailscale.com/download/windows**
2. Install and sign in with the same account
3. You're connected!

#### Mac:
1. Download: **https://tailscale.com/download/mac**
2. Install and sign in
3. You're connected!

#### Linux:
```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

#### Mobile (iOS/Android):
1. Download Tailscale app from App Store / Play Store
2. Sign in with the same account

### Step 6: Connect to RDP via Tailscale

1. Check the workflow output for Tailscale IP (e.g., `100.x.x.x`)
2. Open Remote Desktop client
3. Connect to: `100.x.x.x:3389`
4. Username: `MASTER`
5. Password: `admin@123`

## 🎯 Finding Your Tailscale IP

### Method 1: GitHub Actions Output

1. Go to running workflow
2. Open **"📊 Display Access Information"** step
3. Look for **"🔐 RDP Access (Tailscale VPN)"**
4. Copy the IP address

### Method 2: Tailscale Admin Console

1. Go to: **https://login.tailscale.com/admin/machines**
2. Find device named: `github-rdp-XXXX`
3. Copy the IP address (e.g., `100.x.x.x`)

### Method 3: Command Line (on your device)

```bash
tailscale status
```

Look for `github-rdp-XXXX` in the list.

## 🔄 How It Works

```
GitHub Actions Runner
    ↓
Install Tailscale
    ↓
Start Tailscale Daemon
    ↓
Connect to Your Tailscale Network (using auth key)
    ↓
Get Private IP (100.x.x.x)
    ↓
Your Devices on Same Network Can Connect
    ↓
Direct RDP Connection (no public internet)
```

## 🆚 Tailscale vs Cloudflare Comparison

| Feature | Tailscale VPN | Cloudflare Tunnel |
|---------|---------------|-------------------|
| **Access** | Private (VPN only) | Public (anyone with URL) |
| **IP Address** | Persistent | Changes every restart |
| **Performance** | Better (P2P) | Good (via proxy) |
| **Security** | More secure | Less secure |
| **Setup** | Requires auth key | Automatic |
| **Devices** | Must install Tailscale | Any device |
| **Free Tier** | 100 devices | Unlimited |

## 💡 Best Practices

### Use Both Methods

- **Tailscale**: For your personal secure access
- **Cloudflare**: For sharing or quick access from any device

### Security Tips

1. **Change default password** in `rdp.sh`:
   ```bash
   PASSWORD: "YourStrongPassword123!"
   ```

2. **Use ephemeral keys** - Auto-cleanup when workflow ends

3. **Set key expiration** - Regenerate keys periodically

4. **Enable MFA** on Tailscale account

5. **Monitor devices** in Tailscale admin console

## 🔧 Troubleshooting

### "TAILSCALE_AUTH_KEY not set" Warning

- You haven't added the secret to GitHub
- Follow Step 3 above to add it

### Can't Connect via Tailscale

1. **Check Tailscale is running** on your device:
   ```bash
   tailscale status
   ```

2. **Verify workflow shows Tailscale IP** in output

3. **Check you're on the same Tailscale network**:
   - Both devices should show in: https://login.tailscale.com/admin/machines

4. **Try pinging the IP**:
   ```bash
   ping 100.x.x.x
   ```

### "Auth key expired" Error

1. Generate a new auth key (Step 2)
2. Update GitHub secret (Step 3)
3. Re-run workflow

### Device Not Showing in Tailscale Admin

1. Check workflow logs for errors
2. Verify auth key is correct
3. Make sure key is marked as "Reusable"

## 🎓 Advanced Usage

### Custom Hostname

Edit `.github/workflows/rdp-24-7.yml`:

```yaml
--hostname="my-rdp-server"
```

### Access Control Lists (ACLs)

1. Go to: https://login.tailscale.com/admin/acls
2. Define who can access what
3. Example:
   ```json
   {
     "acls": [
       {
         "action": "accept",
         "src": ["tag:personal"],
         "dst": ["tag:github-actions:*"]
       }
     ]
   }
   ```

### MagicDNS

Enable in Tailscale settings to use hostnames instead of IPs:

```
rdp.my-tailnet.ts.net:3389
```

## 📞 Support

- **Tailscale Docs**: https://tailscale.com/kb/
- **Tailscale Community**: https://forum.tailscale.com/
- **GitHub Issues**: https://github.com/dreamsdevlop/RDp/issues

## ✅ Checklist

- [ ] Created Tailscale account
- [ ] Generated reusable auth key
- [ ] Added `TAILSCALE_AUTH_KEY` to GitHub secrets
- [ ] Installed Tailscale on your device
- [ ] Signed in to Tailscale
- [ ] Started GitHub Actions workflow
- [ ] Found Tailscale IP in workflow output
- [ ] Connected to RDP via Tailscale IP
- [ ] Changed default password

---

**Enjoy secure VPN access to your 24/7 RDP server! 🔐✨**
