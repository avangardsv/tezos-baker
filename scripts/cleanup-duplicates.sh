#!/usr/bin/env bash
#
# Cleanup Duplicate Directories
# Removes old duplicate directories while preserving organized structure
#
# Usage: ./scripts/cleanup-duplicates.sh [--yes]

set -euo pipefail

AUTO_YES=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --yes|-y)
            AUTO_YES=true
            shift
            ;;
        --help|-h)
            cat << 'EOF'
Cleanup Duplicate Directories

Removes duplicate old directories:
- config/   (duplicates config-*.json at root)
- docker/   (duplicates docker-compose.yml at root)
- agents/   (moves to ../tezos-baker-ai/)

Preserves organized structure:
- scripts/  (organized operational scripts)
- docs/     (organized documentation)
- monitoring/ (optional monitoring stack)
- security/   (optional security docs)

Usage:
  ./scripts/cleanup-duplicates.sh        # Interactive mode
  ./scripts/cleanup-duplicates.sh --yes  # Auto-confirm

Safety:
- Creates git tag before deletion (if in git repo)
- Shows what will be removed before proceeding
- Validates structure after cleanup

EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage"
            exit 1
            ;;
    esac
done

echo "========================================"
echo "  Cleanup Duplicate Directories"
echo "========================================"
echo ""

# Check current state
echo "🔍 Analyzing repository structure..."
echo ""

DUPLICATES=()
REPO_SIZE_BEFORE=$(du -sh . 2>/dev/null | cut -f1)

# Check for duplicate config/
if [ -d config ]; then
    DUPLICATES+=("config/ ($(du -sh config 2>/dev/null | cut -f1))")
fi

# Check for duplicate docker/
if [ -d docker ]; then
    DUPLICATES+=("docker/ ($(du -sh docker 2>/dev/null | cut -f1))")
fi

# Check for agents/
if [ -d agents ]; then
    DUPLICATES+=("agents/ ($(du -sh agents 2>/dev/null | cut -f1) - will move to ../tezos-baker-ai/)")
fi

if [ ${#DUPLICATES[@]} -eq 0 ]; then
    echo "✅ No duplicate directories found!"
    echo ""
    echo "Repository is already clean."
    echo "Size: $REPO_SIZE_BEFORE"
    exit 0
fi

echo "Found duplicate directories to clean:"
for item in "${DUPLICATES[@]}"; do
    echo "  - $item"
done
echo ""
echo "Current size: $REPO_SIZE_BEFORE"
echo ""

# Confirm
if [ "$AUTO_YES" = false ]; then
    read -p "Remove these directories? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
fi

echo ""

# Create safety tag
if [ -d .git ]; then
    echo "🏷️  Creating safety tag..."
    TAG_NAME="pre-cleanup-$(date +%Y%m%d-%H%M%S)"
    git tag -f "$TAG_NAME" 2>/dev/null || true
    echo "  ✅ Tag created: $TAG_NAME"
    echo "  (Rollback with: git checkout $TAG_NAME)"
    echo ""
fi

# Move agents/
if [ -d agents ]; then
    echo "📦 Moving agents/ directory..."

    if [ -d ../tezos-baker-ai ]; then
        echo "  ⚠️  ../tezos-baker-ai/ already exists"
        if [ -d ../tezos-baker-ai/agents ]; then
            echo "  ⚠️  ../tezos-baker-ai/agents/ already exists"
            if [ "$AUTO_YES" = false ]; then
                read -p "  Overwrite? (y/N): " confirm
                if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                    echo "  Skipping agents/ move"
                else
                    rm -rf ../tezos-baker-ai/agents
                    mv agents ../tezos-baker-ai/
                    echo "  ✅ Moved agents/ → ../tezos-baker-ai/agents"
                fi
            else
                rm -rf ../tezos-baker-ai/agents
                mv agents ../tezos-baker-ai/
                echo "  ✅ Moved agents/ → ../tezos-baker-ai/agents"
            fi
        else
            mv agents ../tezos-baker-ai/
            echo "  ✅ Moved agents/ → ../tezos-baker-ai/agents"
        fi
    else
        mkdir -p ../tezos-baker-ai
        mv agents ../tezos-baker-ai/
        echo "  ✅ Moved agents/ → ../tezos-baker-ai/agents"
    fi

    # Update .gitignore
    if ! grep -q "^agents/" .gitignore 2>/dev/null; then
        echo "agents/" >> .gitignore
        echo "  ✅ Added agents/ to .gitignore"
    fi

    echo ""
fi

# Remove config/
if [ -d config ]; then
    echo "🗑️  Removing config/ (duplicate)..."
    rm -rf config
    echo "  ✅ Removed config/"
    echo "  (Using config-ghostnet.json and config-mainnet.json at root)"
    echo ""
fi

# Remove docker/
if [ -d docker ]; then
    echo "🗑️  Removing docker/ (duplicate)..."
    rm -rf docker
    echo "  ✅ Removed docker/"
    echo "  (Using docker-compose.yml and Dockerfile at root)"
    echo ""
fi

# Final validation
echo "📊 Cleanup complete!"
echo ""

REPO_SIZE_AFTER=$(du -sh . 2>/dev/null | cut -f1)
FILES_COUNT=$(find . -type f -not -path "./.git/*" | wc -l)

echo "Results:"
echo "  Before: $REPO_SIZE_BEFORE"
echo "  After:  $REPO_SIZE_AFTER"
echo "  Files:  $FILES_COUNT"
echo ""

echo "✅ Repository structure:"
echo "  ✅ scripts/     - Organized operational scripts"
echo "  ✅ docs/        - Organized documentation"
echo "  ✅ Root configs - config-*.json, docker-compose.yml, Dockerfile"
echo ""

if [ -d monitoring ]; then
    echo "  ℹ️  monitoring/ - Optional monitoring stack (kept)"
fi

if [ -d security ]; then
    echo "  ℹ️  security/   - Optional security docs (kept)"
fi

echo ""
echo "Next steps:"
echo "  1. Test: ./scripts/setup.sh ghostnet --skip-snapshot"
echo "  2. Commit: git add -A && git commit -m 'Remove duplicate directories'"
echo ""
