#!/bin/bash

# Script to commit documentation and create GitHub issue for Enhancement 001
# Usage: ./create-issue-001.sh

set -e

echo "🚀 Creating Enhancement 001: Heard Repeats Display"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Step 1: Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}⚠️  GitHub CLI (gh) not found.${NC}"
    echo "Install it with: brew install gh"
    echo "Then run: gh auth login"
    echo ""
    echo "Or create the issue manually at:"
    echo "https://github.com/jtstockton/PocketMesh/issues/new"
    exit 1
fi

# Step 2: Check if authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}⚠️  Not authenticated with GitHub${NC}"
    echo "Run: gh auth login"
    exit 1
fi

# Step 3: Add documentation files
echo "📝 Adding documentation files..."
git add docs/enhancements/
git add .github/ISSUE_TEMPLATE/

# Step 4: Commit
echo "💾 Committing documentation..."
git commit -m "docs: Add enhancement 001 - heard repeats display

- Complete feature specification with corrected technical details
- Architecture documentation with data flow diagrams  
- Step-by-step implementation guide
- GitHub issue template ready to use
- Testing scenarios and edge cases
- Upstream merge compatibility strategy
- Quick reference guides and navigation

All documentation files prepared for implementation of 'Heard N Repeats' 
display feature for channel messages."

# Step 5: Push
echo "⬆️  Pushing to GitHub..."
git push origin main

# Step 6: Create issue
echo "🎫 Creating GitHub issue..."

ISSUE_BODY=$(cat .github/ISSUE_TEMPLATE/001-heard-repeats-feature.md)

gh issue create \
  --title "[FEATURE] Display heard repeat count for flooded channel messages" \
  --body "$ISSUE_BODY" \
  --label "enhancement,ui,messaging" \
  --assignee "@me"

echo ""
echo -e "${GREEN}✅ Success!${NC}"
echo ""
echo "📋 Next steps:"
echo "1. Attach your 4 screenshots to the issue"
echo "2. Review the issue on GitHub"
echo "3. Start implementation following docs/enhancements/001-heard-repeats-implementation-guide.md"
echo ""
echo "📚 Documentation available at: docs/enhancements/"
echo "🚀 Start here: docs/enhancements/START-HERE.md"
