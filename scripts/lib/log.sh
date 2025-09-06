#!/usr/bin/env bash

# Tezos Baker Logging Library
# Provides consistent logging across all workflows and scripts
#
# Usage:
#   source "$(dirname "$0")/lib/log.sh"
#   log_step "STEP_NAME" "START" "Starting operation..."
#   log_step "STEP_NAME" "SUCCESS" "Operation completed"
#   log_step "STEP_NAME" "ERROR" "Operation failed: $error_msg"

set -euo pipefail

# Configuration
LOG_DIR="${LOG_DIR:-logs}"
SCRIPT_NAME="$(basename "${BASH_SOURCE[1]}" .sh)"
LOG_FILE="${LOG_DIR}/${SCRIPT_NAME}_$(date +%F).log"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Color codes for terminal output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Log a workflow step with timestamp, step name, status, and message
# Args: step_name status message
log_step() {
    local step="$1"
    local status="$2"
    local msg="$3"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    
    local log_entry="[$timestamp] $step $status - $msg"
    
    # Write to log file
    echo "$log_entry" >> "$LOG_FILE"
    
    # Also output to console with colors
    case "$status" in
        "START")
            echo -e "${BLUE}[$timestamp] $step $status - $msg${NC}" >&2
            ;;
        "SUCCESS")
            echo -e "${GREEN}[$timestamp] $step $status - $msg${NC}" >&2
            ;;
        "ERROR")
            echo -e "${RED}[$timestamp] $step $status - $msg${NC}" >&2
            ;;
        "WARNING")
            echo -e "${YELLOW}[$timestamp] $step $status - $msg${NC}" >&2
            ;;
        *)
            echo -e "[$timestamp] $step $status - $msg" >&2
            ;;
    esac
}

# Helper function to run a command with automatic logging
# Args: step_name command_description command [args...]
run_logged_command() {
    local step="$1"
    local description="$2"
    shift 2
    
    log_step "$step" "START" "$description"
    
    local start_time
    start_time=$(date +%s)
    
    if "$@" 2>&1 | tee -a "$LOG_FILE" >/dev/null; then
        local end_time duration
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        log_step "$step" "SUCCESS" "$description completed in ${duration}s"
        return 0
    else
        local exit_code=$?
        log_step "$step" "ERROR" "$description failed with exit code $exit_code"
        return $exit_code
    fi
}

# Log script initialization
log_script_start() {
    local script_desc="${1:-}"
    log_step "SCRIPT_INIT" "START" "Starting $SCRIPT_NAME${script_desc:+ - $script_desc}"
    log_step "SCRIPT_INIT" "INFO" "Log file: $LOG_FILE"
    log_step "SCRIPT_INIT" "INFO" "Working directory: $(pwd)"
    log_step "SCRIPT_INIT" "INFO" "User: $(whoami)"
    log_step "SCRIPT_INIT" "INFO" "Arguments: $*"
}

# Log script completion
log_script_end() {
    local exit_code="${1:-0}"
    if [ "$exit_code" -eq 0 ]; then
        log_step "SCRIPT_INIT" "SUCCESS" "$SCRIPT_NAME completed successfully"
    else
        log_step "SCRIPT_INIT" "ERROR" "$SCRIPT_NAME failed with exit code $exit_code"
    fi
}

# Set up trap to log script end automatically
trap 'log_script_end $?' EXIT

# Helper function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Helper function to log system information
log_system_info() {
    log_step "SYSTEM_INFO" "INFO" "OS: $(uname -s) $(uname -r)"
    log_step "SYSTEM_INFO" "INFO" "Docker: $(docker --version 2>/dev/null || echo 'Not installed')"
    log_step "SYSTEM_INFO" "INFO" "Docker Compose: $(docker compose version 2>/dev/null || echo 'Not installed')"
    log_step "SYSTEM_INFO" "INFO" "Available disk space: $(df -h . | tail -1 | awk '{print $4}')"
    log_step "SYSTEM_INFO" "INFO" "Memory: $(free -h 2>/dev/null | grep Mem | awk '{print $7}' || echo 'N/A')"
}

# Helper function to validate prerequisites
validate_prerequisites() {
    local required_commands=("$@")
    local missing_commands=()
    
    for cmd in "${required_commands[@]}"; do
        if ! command_exists "$cmd"; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [ ${#missing_commands[@]} -gt 0 ]; then
        log_step "PREREQUISITES" "ERROR" "Missing required commands: ${missing_commands[*]}"
        return 1
    fi
    
    log_step "PREREQUISITES" "SUCCESS" "All required commands available: ${required_commands[*]}"
    return 0
}

# Export functions for use in other scripts
export -f log_step
export -f run_logged_command
export -f log_script_start
export -f log_script_end
export -f command_exists
export -f log_system_info
export -f validate_prerequisites