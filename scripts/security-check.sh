#!/usr/bin/env bash
# Security check before publishing repository
# Run this script to verify no secrets are exposed

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔒 Security Check for Repository Publication"
echo "==========================================="
echo ""

ERRORS=0
WARNINGS=0

# Check 1: .env file never committed
echo "✓ Checking if .env was ever committed..."
if git log --all --full-history -- .env | grep -q "commit"; then
    echo -e "${RED}✗ CRITICAL: .env file found in git history!${NC}"
    ((ERRORS++))
else
    echo -e "${GREEN}✓ Good: .env never committed${NC}"
fi
echo ""

# Check 2: Secret keys (edsk) in history
echo "✓ Checking for secret keys in git history..."
if git log --all -p | grep -q "edsk"; then
    echo -e "${RED}✗ CRITICAL: Secret key (edsk) found in git history!${NC}"
    echo "  This is a CRITICAL security issue. DO NOT publish!"
    ((ERRORS++))
else
    echo -e "${GREEN}✓ Good: No secret keys found${NC}"
fi
echo ""

# Check 3: Check for addresses other than testnet
echo "✓ Checking for Tezos addresses in git history..."
ADDRESSES=$(git log --all -p | grep -oE "tz[1-4][a-zA-Z0-9]{33}" | sort -u || echo "")
if [ -n "$ADDRESSES" ]; then
    echo -e "${YELLOW}⚠ Found Tezos addresses (verify these are testnet only):${NC}"
    echo "$ADDRESSES"
    ((WARNINGS++))
else
    echo -e "${GREEN}✓ Good: No addresses found${NC}"
fi
echo ""

# Check 4: Check .gitignore has required entries
echo "✓ Checking .gitignore configuration..."
GITIGNORE_OK=true
for dir in "data/" ".env" "dal-data/" "backups/"; do
    if ! grep -q "^$dir" .gitignore; then
        echo -e "${RED}✗ Missing in .gitignore: $dir${NC}"
        GITIGNORE_OK=false
        ((ERRORS++))
    fi
done
if [ "$GITIGNORE_OK" = true ]; then
    echo -e "${GREEN}✓ Good: .gitignore properly configured${NC}"
fi
echo ""

# Check 5: Check for email addresses
echo "✓ Checking for personal email addresses..."
EMAILS=$(git log | grep -oE "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}" | grep -v "noreply@" | sort -u || echo "")
if [ -n "$EMAILS" ]; then
    echo -e "${YELLOW}⚠ Found email addresses:${NC}"
    echo "$EMAILS"
    echo "  (This may be OK if they're public contacts)"
    ((WARNINGS++))
else
    echo -e "${GREEN}✓ Good: No personal emails found${NC}"
fi
echo ""

# Check 6: Required files exist
echo "✓ Checking required documentation files..."
DOCS_OK=true
for file in "LICENSE" "CONTRIBUTING.md" "PUBLISHING-CHECKLIST.md"; do
    if [ ! -f "$file" ]; then
        echo -e "${RED}✗ Missing: $file${NC}"
        DOCS_OK=false
        ((ERRORS++))
    fi
done
if [ "$DOCS_OK" = true ]; then
    echo -e "${GREEN}✓ Good: All required docs present${NC}"
fi
echo ""

# Check 7: README has warning
echo "✓ Checking README.md has educational warning..."
if grep -q "Educational Project - Not for Production" README.md; then
    echo -e "${GREEN}✓ Good: README has proper warning${NC}"
else
    echo -e "${RED}✗ Missing: Educational warning in README${NC}"
    ((ERRORS++))
fi
echo ""

# Summary
echo "==========================================="
echo "Security Check Summary:"
echo ""
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ ALL CHECKS PASSED!${NC}"
    echo "Your repository appears safe to publish."
    echo ""
    echo "Next steps:"
    echo "1. Review PUBLISHING-CHECKLIST.md for final steps"
    echo "2. Commit changes: git commit -m 'Prepare for public release'"
    echo "3. Push to GitHub: git push origin main"
    echo "4. Make repository public in GitHub settings"
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  PASSED WITH WARNINGS (${WARNINGS} warnings)${NC}"
    echo "Review warnings above and verify they're acceptable."
    echo "You can proceed with publication if warnings are OK."
else
    echo -e "${RED}❌ FAILED (${ERRORS} errors, ${WARNINGS} warnings)${NC}"
    echo ""
    echo "DO NOT PUBLISH until all errors are fixed!"
    echo "Critical security issues were found."
    exit 1
fi
