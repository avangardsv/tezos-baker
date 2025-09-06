#!/usr/bin/env bash

# Tezos Baker - Logging System Test Script
# Tests the logging workflow and generates example logs for demonstration
#
# Usage: ./test_logging.sh [--generate-examples]
#   --generate-examples: Create realistic example log entries

set -euo pipefail

# Source logging library
source "$(dirname "$0")/lib/log.sh"

# Initialize script logging
log_script_start "Test logging system functionality"

# Test basic logging functions
test_basic_logging() {
    log_step "BASIC_LOGGING" "START" "Testing basic logging functions"
    
    # Test all log levels
    log_step "TEST_STEP" "START" "Beginning test operation"
    sleep 1
    log_step "TEST_STEP" "SUCCESS" "Test operation completed successfully"
    log_step "TEST_STEP" "INFO" "This is an informational message"
    log_step "TEST_STEP" "WARNING" "This is a warning message"
    log_step "TEST_STEP" "ERROR" "This is an error message (simulated)"
    
    log_step "BASIC_LOGGING" "SUCCESS" "All log levels tested"
}

# Test command execution logging
test_command_logging() {
    log_step "COMMAND_LOGGING" "START" "Testing command execution logging"
    
    # Test successful command
    run_logged_command "TEST_SUCCESS" "Testing successful command" echo "Hello from test command"
    
    # Test command with output
    run_logged_command "TEST_OUTPUT" "Testing command with output" ls -la /tmp | head -5
    
    # Test command that generates some processing time
    run_logged_command "TEST_TIMING" "Testing command timing" sleep 2
    
    log_step "COMMAND_LOGGING" "SUCCESS" "Command logging tests completed"
}

# Test system information logging
test_system_logging() {
    log_step "SYSTEM_LOGGING" "START" "Testing system information logging"
    
    log_system_info
    
    log_step "SYSTEM_LOGGING" "SUCCESS" "System information logged"
}

# Test prerequisite validation
test_prerequisite_validation() {
    log_step "PREREQUISITE_TEST" "START" "Testing prerequisite validation"
    
    # Test with existing commands
    validate_prerequisites "bash" "echo" "ls"
    
    log_step "PREREQUISITE_TEST" "SUCCESS" "Prerequisite validation tested"
}

# Generate realistic example log entries
generate_example_logs() {
    log_step "EXAMPLE_GENERATION" "START" "Generating realistic example log entries"
    
    # Simulate snapshot import workflow
    log_step "SNAPSHOT_DOWNLOAD" "START" "Downloading ghostnet snapshot from https://snapshots.tezos.giganode.io"
    sleep 1
    log_step "SNAPSHOT_DOWNLOAD" "INFO" "Download progress: 25% (125MB/500MB)"
    sleep 1
    log_step "SNAPSHOT_DOWNLOAD" "INFO" "Download progress: 75% (375MB/500MB)"
    sleep 1
    log_step "SNAPSHOT_DOWNLOAD" "SUCCESS" "Downloaded ghostnet.full (500MB) in 3m45s"
    
    # Simulate import process
    log_step "SNAPSHOT_IMPORT" "START" "Importing snapshot into Tezos node"
    sleep 1
    log_step "SNAPSHOT_IMPORT" "INFO" "Validating snapshot integrity"
    sleep 1
    log_step "SNAPSHOT_IMPORT" "INFO" "Import progress: 50% - processing block 2,450,000"
    sleep 1
    log_step "SNAPSHOT_IMPORT" "SUCCESS" "Snapshot imported successfully in 2m30s"
    
    # Simulate node startup
    log_step "NODE_START" "START" "Starting Tezos node on ghostnet"
    sleep 1
    log_step "NODE_START" "INFO" "Node started with PID=12345"
    log_step "NODE_START" "INFO" "Connecting to network peers"
    sleep 1
    log_step "NODE_START" "SUCCESS" "Connected to 15 peers, bootstrapping blockchain"
    
    # Simulate sync monitoring
    log_step "SYNC_CHECK" "START" "Monitoring node synchronization"
    log_step "SYNC_CHECK" "INFO" "Current head: 2,450,123, Network head: 2,450,125 (lag: 2 blocks)"
    sleep 1
    log_step "SYNC_CHECK" "SUCCESS" "Node is synchronized (lag: 0 blocks)"
    
    # Simulate delegate registration
    log_step "DELEGATE_REGISTRATION" "START" "Registering 'alice' as delegate"
    log_step "DELEGATE_REGISTRATION" "INFO" "Account balance: 6500 XTZ (sufficient for baking)"
    sleep 1
    log_step "DELEGATE_REGISTRATION" "INFO" "Registration transaction: ooBgHcpKxvHjzSvb4ELV5fLrLEq8"
    sleep 1
    log_step "DELEGATE_REGISTRATION" "SUCCESS" "Delegate registration confirmed in block 2,450,128"
    
    # Simulate baker startup
    log_step "BAKER_START" "START" "Starting Tezos baker for 'alice'"
    sleep 1
    log_step "BAKER_START" "SUCCESS" "Baker started successfully (PID: 12567)"
    log_step "ENDORSER_START" "START" "Starting Tezos endorser for 'alice'"
    sleep 1
    log_step "ENDORSER_START" "SUCCESS" "Endorser started successfully (PID: 12568)"
    
    # Simulate some operational activity
    log_step "BAKING_ACTIVITY" "INFO" "Baking rights found for levels 2,450,145-2,450,147"
    log_step "BAKING_ACTIVITY" "SUCCESS" "Successfully baked block 2,450,145"
    log_step "ENDORSING_ACTIVITY" "SUCCESS" "Successfully endorsed block 2,450,146"
    
    # Simulate a warning scenario
    log_step "SYNC_CHECK" "WARNING" "Head lag increased to 8 blocks - investigating"
    sleep 1
    log_step "SYNC_CHECK" "INFO" "Network connectivity restored"
    log_step "SYNC_CHECK" "SUCCESS" "Head lag reduced to 1 block"
    
    log_step "EXAMPLE_GENERATION" "SUCCESS" "Generated realistic example log entries"
}

# Test log file operations
test_log_file_operations() {
    log_step "LOG_FILE_TEST" "START" "Testing log file operations"
    
    # Check if log file exists and is writable
    if [ -f "$LOG_FILE" ]; then
        log_step "LOG_FILE_TEST" "SUCCESS" "Log file exists: $LOG_FILE"
        
        # Check log file size
        local log_size
        log_size=$(du -h "$LOG_FILE" | cut -f1)
        log_step "LOG_FILE_TEST" "INFO" "Log file size: $log_size"
        
        # Count log entries
        local entry_count
        entry_count=$(grep -c "\[.*\].*\(START\|SUCCESS\|ERROR\|WARNING\|INFO\)" "$LOG_FILE" 2>/dev/null || echo "0")
        log_step "LOG_FILE_TEST" "INFO" "Total log entries: $entry_count"
        
        # Test log parsing
        local error_count warning_count success_count
        error_count=$(grep -c "ERROR" "$LOG_FILE" 2>/dev/null || echo "0")
        warning_count=$(grep -c "WARNING" "$LOG_FILE" 2>/dev/null || echo "0") 
        success_count=$(grep -c "SUCCESS" "$LOG_FILE" 2>/dev/null || echo "0")
        
        log_step "LOG_FILE_TEST" "INFO" "Log entry breakdown - SUCCESS: $success_count, WARNING: $warning_count, ERROR: $error_count"
        
    else
        log_step "LOG_FILE_TEST" "ERROR" "Log file not found: $LOG_FILE"
        return 1
    fi
    
    log_step "LOG_FILE_TEST" "SUCCESS" "Log file operations tested successfully"
}

# Display log file contents (last 20 lines)
show_recent_logs() {
    log_step "LOG_DISPLAY" "START" "Showing recent log entries"
    
    echo ""
    echo "=== Recent Log Entries (last 20 lines) ==="
    tail -20 "$LOG_FILE" || echo "Could not read log file"
    echo "============================================"
    echo ""
    
    log_step "LOG_DISPLAY" "SUCCESS" "Recent logs displayed"
}

# Show usage information
show_usage() {
    cat << EOF
Tezos Baker Logging Test

Usage: $0 [options]

Options:
  --generate-examples  Generate realistic example log entries
  --help, -h          Show this help message

Description:
  Tests the logging system functionality and generates example logs
  for demonstration and validation purposes.

Test Coverage:
  - Basic logging functions (all levels)
  - Command execution logging
  - System information logging  
  - Prerequisite validation
  - Log file operations
  - Example log generation (with --generate-examples)

Output:
  All test results are logged to: logs/test_logging_<date>.log
  
Examples:
  $0                    # Run basic logging tests
  $0 --generate-examples # Run tests and generate realistic examples

Exit codes:
  0  All tests passed
  1  Some tests failed
  2  Configuration error
EOF
}

# Main execution
main() {
    local generate_examples=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --generate-examples)
                generate_examples=true
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                log_step "ARGUMENTS" "ERROR" "Unknown argument: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    log_system_info
    
    # Run test suite
    test_basic_logging
    test_command_logging
    test_system_logging
    test_prerequisite_validation
    
    # Generate examples if requested
    if [ "$generate_examples" = true ]; then
        generate_example_logs
    fi
    
    # Test log file operations
    test_log_file_operations
    
    # Show recent logs
    show_recent_logs
    
    log_step "TEST_COMPLETE" "SUCCESS" "All logging tests completed successfully"
    log_step "TEST_COMPLETE" "INFO" "Log file location: $LOG_FILE"
    log_step "TEST_COMPLETE" "INFO" "Use 'tail -f $LOG_FILE' to monitor logs in real-time"
}

# Execute main function
main "$@"