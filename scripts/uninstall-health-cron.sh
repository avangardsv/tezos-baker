#!/bin/bash
# Uninstall health check cron job

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  HEALTH CHECK CRON UNINSTALLER${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if health check in crontab
if ! crontab -l 2>/dev/null | grep -q "health-check.sh"; then
    echo -e "${YELLOW}[INFO] No health check cron job found${NC}"
    echo ""
    exit 0
fi

echo "Current health check cron job:"
crontab -l 2>/dev/null | grep "health-check.sh"
echo ""

read -p "Remove this cron job? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled"
    exit 0
fi

# Remove cron job
crontab -l 2>/dev/null | grep -v "health-check.sh" | crontab -

echo -e "${GREEN}[OK] Cron job removed${NC}"
echo ""
