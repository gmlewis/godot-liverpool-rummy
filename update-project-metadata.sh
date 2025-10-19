#!/bin/bash
# Update project_metadata.cfg in the repository
# This script temporarily disables skip-worktree protection to commit changes

set -e

PROJECT_METADATA=".godot/editor/project_metadata.cfg"
COMMIT_MSG="Update project metadata from Mac"

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "Error: Not in a git repository"
    exit 1
fi

# Check if file exists
if [ ! -f "$PROJECT_METADATA" ]; then
    echo "Error: $PROJECT_METADATA not found"
    exit 1
fi

# Check if there are any changes to the file
git diff --quiet "$PROJECT_METADATA" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "No changes detected in $PROJECT_METADATA"
    echo "Nothing to update."
    exit 0
fi

echo "Updating $PROJECT_METADATA in repository..."
echo ""

# Temporarily disable skip-worktree
echo "1. Removing skip-worktree protection..."
git update-index --no-skip-worktree "$PROJECT_METADATA"

# Stage the file
echo "2. Staging changes..."
git add "$PROJECT_METADATA"

# Allow custom commit message
if [ -n "$1" ]; then
    COMMIT_MSG="$1"
fi

# Commit the changes
echo "3. Committing with message: '$COMMIT_MSG'"
git commit -m "$COMMIT_MSG"

# Re-enable skip-worktree
echo "4. Re-enabling skip-worktree protection..."
git update-index --skip-worktree "$PROJECT_METADATA"

echo ""
echo "✓ Successfully updated $PROJECT_METADATA"
echo "✓ Skip-worktree protection re-enabled"
echo ""
echo "You can now push this change with: git push"
