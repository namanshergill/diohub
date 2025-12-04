#!/bin/bash

# Script to remove build/ directory from git history using git filter-repo
# WARNING: This rewrites git history. Make sure you have a backup!
# Requires: git filter-repo (https://github.com/newren/git-filter-repo/)

set -e

cd "$(dirname "$0")"

# Check if git filter-repo is installed
if ! command -v git filter-repo &> /dev/null; then
    echo "Error: git filter-repo is not installed."
    echo "Install it with: pip install git-filter-repo"
    echo "Or visit: https://github.com/newren/git-filter-repo/"
    exit 1
fi

# Check for unstaged changes
if ! git diff-index --quiet HEAD --; then
    echo "Warning: You have unstaged changes."
    echo "Stashing changes before proceeding..."
    git stash push -m "Stashing changes before running git filter script"
    STASHED=true
else
    STASHED=false
fi

echo "Step 1: Removing build/ directory from git history..."
echo "This may take a while..."

# Remove build/ directory from all commits using git filter-repo
# --invert-paths means "remove these paths" instead of "keep only these paths"
git filter-repo --path build/ --invert-paths --force

echo ""
echo "Step 2: Running garbage collection..."
git gc --prune=now --aggressive

echo ""
echo "Step 3: Checking repository size..."
du -sh .git

# Restore stashed changes if any
if [ "$STASHED" = true ]; then
    echo ""
    echo "Restoring stashed changes..."
    git stash pop || echo "Note: Some conflicts may have occurred during stash pop"
fi

echo ""
echo "Done! Repository cleanup complete."
echo ""
echo "IMPORTANT: If you've already pushed this repository to a remote:"
echo "  - You'll need to force push: git push --force --all"
echo "  - And force push tags: git push --force --tags"
echo "  - Warn your collaborators first!"

