#!/bin/bash
# Quick start script to begin a new AI-assisted session with logging compliance

set -euo pipefail

echo "🚀 Starting AI-assisted session with logging compliance"
echo "📅 Date: $(date +%F)"
echo ""

# Check if logging script exists
if [ ! -f "scripts/ai_log.sh" ]; then
    echo "❌ ERROR: scripts/ai_log.sh not found!"
    exit 1
fi

# Check if .ai directory exists
if [ ! -d ".ai" ]; then
    echo "📁 Creating .ai directory..."
    mkdir -p .ai
fi

# Log session start
echo "Starting AI-assisted session" | scripts/ai_log.sh session start \
    --files .claude/settings.local.json \
    --meta session_type=ai_assistance

echo "✅ Session started with logging compliance"
echo "📋 Remember: Log every AI step using scripts/ai_log.sh"
echo "📋 Create daily summary at logs/ai/$(date +%F).md"
echo ""
echo "🎯 Ready to begin work!"
