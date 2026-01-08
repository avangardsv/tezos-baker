#!/usr/bin/env bash
# Platform detection and OS-specific commands
# Source this file: source "$(dirname "$0")/platform.sh"

set -euo pipefail

# =============================================================================
# PLATFORM DETECTION
# =============================================================================

detect_os() {
    case "$(uname -s)" in
        Darwin*)
            echo "macos"
            ;;
        Linux*)
            echo "linux"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

is_macos() {
    [ "$(detect_os)" = "macos" ]
}

is_linux() {
    [ "$(detect_os)" = "linux" ]
}

# =============================================================================
# MACOS-SPECIFIC COMMANDS
# =============================================================================

# Get system sleep/wake information (macOS only)
get_sleep_status_macos() {
    if ! is_macos; then
        echo "⚠️  This command is macOS-specific." >&2
        return 1
    fi
    
    if ! command -v pmset >/dev/null 2>&1; then
        echo "❌ Error: 'pmset' command not found." >&2
        return 1
    fi
    
    echo "System uptime:"
    uptime
    echo ""
    echo "Sleep/Wake count:"
    pmset -g log | grep -c 'Wake from' || echo "0"
    echo ""
    echo "Recent wakes:"
    pmset -g log | grep 'Wake from' | tail -5
}

# Prevent system sleep (macOS only)
prevent_sleep_macos() {
    if ! is_macos; then
        echo "⚠️  This command is macOS-specific." >&2
        return 1
    fi
    
    if ! command -v caffeinate >/dev/null 2>&1; then
        echo "❌ Error: 'caffeinate' command not found." >&2
        return 1
    fi
    
    echo "⚠️  Preventing Mac sleep - Press Ctrl+C to stop"
    caffeinate -d
}

# =============================================================================
# LINUX-SPECIFIC COMMANDS
# =============================================================================

# Get system sleep/wake information (Linux alternative)
get_sleep_status_linux() {
    if ! is_linux; then
        echo "⚠️  This command is Linux-specific." >&2
        return 1
    fi
    
    echo "System uptime:"
    uptime
    echo ""
    echo "Last boot:"
    who -b 2>/dev/null || last reboot | head -1
}

# Prevent system sleep (Linux alternative)
prevent_sleep_linux() {
    if ! is_linux; then
        echo "⚠️  This command is Linux-specific." >&2
        return 1
    fi
    
    echo "⚠️  Preventing system sleep (Linux)"
    echo "   Use 'systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target' for systemd"
    echo "   Or use 'xset s off -dpms' for X11"
    echo "   Press Ctrl+C to stop"
    
    # Simple keep-alive loop
    while true; do
        sleep 60
    done
}

# =============================================================================
# CROSS-PLATFORM WRAPPERS
# =============================================================================

get_sleep_status() {
    case "$(detect_os)" in
        macos)
            get_sleep_status_macos
            ;;
        linux)
            get_sleep_status_linux
            ;;
        *)
            echo "⚠️  Unsupported platform: $(uname -s)" >&2
            return 1
            ;;
    esac
}

prevent_sleep() {
    case "$(detect_os)" in
        macos)
            prevent_sleep_macos
            ;;
        linux)
            prevent_sleep_linux
            ;;
        *)
            echo "⚠️  Unsupported platform: $(uname -s)" >&2
            return 1
            ;;
    esac
}

