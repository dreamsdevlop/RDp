# 💾 Smart Data Backup Setup (OPTIONAL)

> **This is completely optional!** The RDP works perfectly without Rclone.
> Only set this up if you want to keep files between workflow restarts.

This project supports automatic backup of your RDP data to Google Drive, OneDrive, Dropbox, etc. using **Rclone**.

## 1. Install Rclone Locally
You need to generate the config file on your own computer first.
- **Windows**: [Download here](https://rclone.org/downloads/)
- **Mac/Linux**: Run `curl https://rclone.org/install.sh | sudo bash`

## 2. Create Config
Run the following command in your terminal:
```bash
rclone config
```
1.  Press `n` for **New Remote**.
2.  Name it `remote` (Must be exactly `remote`).
3.  Select your storage provider (e.g., `drive` for Google Drive).
4.  Follow the on-screen instructions to authenticate.
5.  Keep defaults for most other options.

## 3. Get the Config Content
Once finished, run:
```bash
rclone config show
```
Copy the **entire output** (starting from `[remote]` to the end).

## 4. Add to GitHub Secrets
1.  Go to your GitHub Repo -> **Settings** -> **Secrets and variables** -> **Actions**.
2.  Click **New repository secret**.
3.  **Name**: `RCLONE_CONFIG`
4.  **Secret**: Paste the config you copied.
5.  Click **Add secret**.

## 5. How to Use
- Inside your Windows RDP, you will see a folder mapped to `Z:` or inside `C:\storage` (depending on mount).
- **IMPORTANT**: Only files inside `C:\storage\data` (or the folder created by the script) will be backed up!
- The script syncs every 10 minutes.
