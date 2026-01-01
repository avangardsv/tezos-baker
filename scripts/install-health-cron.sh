#!/bin/bash
# Install cron job for automated health checks

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  HEALTH CHECK CRON INSTALLER${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if health check already in crontab
if crontab -l 2>/dev/null | grep -q "health-check.sh"; then
    echo -e "${YELLOW}[INFO] Health check cron job already exists${NC}"
    echo ""
    echo "Current cron schedule:"
    crontab -l 2>/dev/null | grep "health-check.sh"
    echo ""
    read -p "Do you want to remove and reinstall? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled"
        exit 0
    fi

    # Remove existing cron job
    crontab -l 2>/dev/null | grep -v "health-check.sh" | crontab -
    echo -e "${GREEN}[OK] Removed existing cron job${NC}"
fi

# Create cron entry
# Format: minute hour day month weekday command
# 0 * * * * = every hour at minute 0
CRON_CMD="0 * * * * cd $PROJECT_DIR && npm run health:check >> logs/health-cron.log 2>&1"

# Add to crontab
(crontab -l 2>/dev/null; echo "$CRON_CMD") | crontab -

echo -e "${GREEN}[OK] Cron job installed successfully${NC}"
echo ""
echo -e "${BLUE}Schedule:${NC} Every hour at minute 0 (e.g., 10:00, 11:00, 12:00...)"
echo -e "${BLUE}Command:${NC}  npm run health:check"
echo -e "${BLUE}Logs:${NC}     logs/health-cron.log"
echo ""
echo -e "${YELLOW}Current crontab:${NC}"
crontab -l
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}To remove cron job:${NC} crontab -e (then delete the health-check line)"
echo -e "${GREEN}To view logs:${NC}       tail -f logs/health-cron.log"
echo -e "${GREEN}To test now:${NC}        npm run health:check"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
