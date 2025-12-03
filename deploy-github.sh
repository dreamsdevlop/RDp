#!/bin/bash
# ============================================
# 🚀 Quick Deploy to GitHub Actions for 24/7 RDP
# ============================================

set -e

echo "=========================================="
echo "🚀 GitHub Actions 24/7 RDP Deployment"
echo "=========================================="
echo ""

# Check if git is initialized
if [ ! -d ".git" ]; then
    echo "📦 Initializing Git repository..."
    git init
    echo "✅ Git initialized"
else
    echo "✅ Git repository already exists"
fi

# Check if remote exists
if ! git remote | grep -q "origin"; then
    echo ""
    echo "❓ Enter your GitHub repository URL:"
    echo "   Example: https://github.com/username/rdp-24-7.git"
    read -p "   URL: " REPO_URL
    
    if [ -z "$REPO_URL" ]; then
        echo "❌ No URL provided. Exiting."
        exit 1
    fi
    
    git remote add origin "$REPO_URL"
    echo "✅ Remote 'origin' added"
else
    echo "✅ Remote 'origin' already configured"
    git remote -v
fi

echo ""
echo "📝 Staging files..."
git add .

echo ""
echo "💾 Creating commit..."
git commit -m "Setup 24/7 RDP with GitHub Actions" || echo "⚠️ No changes to commit"

echo ""
echo "🚀 Pushing to GitHub..."
BRANCH=$(git rev-parse --abbrev-ref HEAD)
git push -u origin "$BRANCH"

echo ""
echo "=========================================="
echo "✅ Deployment Complete!"
echo "=========================================="
echo ""
echo "📋 Next Steps:"
echo ""
echo "1. Go to your GitHub repository:"
echo "   $(git remote get-url origin | sed 's/\.git$//')"
echo ""
echo "2. Enable GitHub Actions:"
echo "   Settings → Actions → General"
echo "   → Allow all actions and reusable workflows"
echo ""
echo "3. Start the workflow:"
echo "   Actions tab → '24/7 Live RDP' → 'Run workflow'"
echo ""
echo "4. Wait 2-3 minutes and check workflow output for:"
echo "   🌍 Web Console URL"
echo "   🖥️  RDP Access URL"
echo ""
echo "🔑 Default Credentials:"
echo "   Username: MASTER"
echo "   Password: admin@123"
echo ""
echo "=========================================="
echo "🎉 Your 24/7 RDP will be live soon!"
echo "=========================================="
