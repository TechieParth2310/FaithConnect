#!/bin/bash

# Script to push FaithConnect to GitHub
# Make sure you've created the repository on GitHub first!

echo "🚀 FaithConnect GitHub Push Script"
echo "===================================="
echo ""

# Check if remote already exists
if git remote get-url origin &>/dev/null; then
    echo "✅ Remote 'origin' already configured"
    REMOTE_URL=$(git remote get-url origin)
    echo "   Current remote: $REMOTE_URL"
    echo ""
    read -p "Do you want to use this remote? (y/n): " use_existing
    if [ "$use_existing" != "y" ]; then
        echo "Please set your repository URL:"
        read -p "Enter your GitHub username: " GITHUB_USER
        read -p "Enter repository name (default: FaithConnect): " REPO_NAME
        REPO_NAME=${REPO_NAME:-FaithConnect}
        git remote set-url origin "https://github.com/$GITHUB_USER/$REPO_NAME.git"
    fi
else
    echo "📝 Setting up GitHub remote..."
    read -p "Enter your GitHub username: " GITHUB_USER
    read -p "Enter repository name (default: FaithConnect): " REPO_NAME
    REPO_NAME=${REPO_NAME:-FaithConnect}
    
    git remote add origin "https://github.com/$GITHUB_USER/$REPO_NAME.git"
    echo "✅ Remote added: https://github.com/$GITHUB_USER/$REPO_NAME.git"
fi

echo ""
echo "📤 Pushing to GitHub..."
echo ""

# Set main branch
git branch -M main

# Push to GitHub
if git push -u origin main; then
    echo ""
    echo "✅ Successfully pushed to GitHub!"
    echo ""
    echo "🔒 Don't forget to make the repository PRIVATE:"
    echo "   1. Go to: https://github.com/$GITHUB_USER/$REPO_NAME/settings"
    echo "   2. Scroll to 'Danger Zone'"
    echo "   3. Click 'Change visibility' → 'Make private'"
    echo ""
else
    echo ""
    echo "❌ Push failed. Common issues:"
    echo "   - Repository doesn't exist on GitHub yet"
    echo "   - Authentication required (use GitHub CLI or Personal Access Token)"
    echo "   - Check: https://github.com/$GITHUB_USER/$REPO_NAME"
    echo ""
    echo "💡 To create the repository first:"
    echo "   Visit: https://github.com/new"
    echo "   Name: $REPO_NAME"
    echo "   Visibility: Private ✅"
    echo "   DO NOT initialize with README/gitignore"
    echo ""
fi
