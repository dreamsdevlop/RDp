# ⏸️ Pause/Resume RDP Workflow

The 24/7 RDP workflow can now be paused and resumed using a repository variable.

## 🎮 How to Control the Workflow

### ▶️ To RESUME (Enable) RDP:
1. Go to: https://github.com/dreamsdevlop/RDp/settings/variables/actions
2. Find the variable `RDP_ENABLED`
3. Set value to: `true`
4. Click **Update variable**

**OR** if the variable doesn't exist yet:
1. Click **New repository variable**
2. Name: `RDP_ENABLED`
3. Value: `true`
4. Click **Add variable**

### ⏸️ To PAUSE (Disable) RDP:
1. Go to: https://github.com/dreamsdevlop/RDp/settings/variables/actions
2. Find the variable `RDP_ENABLED`
3. Set value to: `false`
4. Click **Update variable**

## 📊 What Happens

### When ENABLED (`RDP_ENABLED=true` or not set):
- ✅ Workflow runs every 5 hours automatically
- ✅ RDP stays online 24/7
- ✅ Tailscale IP `100.91.158.105:3389` remains accessible

### When PAUSED (`RDP_ENABLED=false`):
- 🛑 Scheduled runs are skipped
- 🛑 RDP goes offline
- ℹ️ You can still manually trigger via "Run workflow" button

## 💡 Use Cases

**Pause when:**
- You don't need RDP for a while (save GitHub Actions minutes)
- You're traveling and won't use it
- You want to stop automatic restarts

**Resume when:**
- You need 24/7 access again
- You want automatic reconnection

## 🚀 Quick Actions

### Check Current Status:
Go to: https://github.com/dreamsdevlop/RDp/actions
- If you see "🛑 RDP is PAUSED" → It's disabled
- If you see "✅ RDP is ENABLED" → It's running

### Manual Override:
Even when paused, you can manually start RDP:
1. Go to: https://github.com/dreamsdevlop/RDp/actions/workflows/rdp-24-7.yml
2. Click **Run workflow**
3. Select branch: `main`
4. Click **Run workflow**

## ⚙️ Default Behavior
- **If variable is not set**: RDP is ENABLED (runs automatically)
- **If variable is set to anything except "false"**: RDP is ENABLED
- **Only when set to "false"**: RDP is PAUSED
