#!/usr/bin/env bash

# Tezos Baker - Log Validation Script
# Validates log files for format compliance and completeness
#
# Usage: ./validate_logs.sh [log_file_or_directory] [--strict]
#   log_file_or_directory: Specific file or directory to validate (default: logs/)
#   --strict: Enable strict validation mode

set -euo pipefail

# Source logging library
source "$(dirname "$0")/lib/log.sh"

# Configuration
TARGET="${1:-logs}"
STRICT_MODE=false

# Initialize script logging
log_script_start "Validate log files for format compliance"

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --strict)
                STRICT_MODE=true
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                break
                ;;
        esac
    done
}

# Validate log file format
validate_log_format() {
    local log_file="$1"
    
    log_step "FORMAT_CHECK" "START" "Validating format for $(basename "$log_file")"
    
    if [ ! -f "$log_file" ]; then
        log_step "FORMAT_CHECK" "ERROR" "Log file not found: $log_file"
        return 1
    fi
    
    local total_lines malformed_lines
    total_lines=$(wc -l < "$log_file")
    
    # Expected format: [YYYY-MM-DD HH:MM:SS] STEP_NAME STATUS - MESSAGE
    local format_regex='^\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\] [A-Z_]+ (START|SUCCESS|ERROR|WARNING|INFO) - .*'
    
    # Count properly formatted lines
    local formatted_lines
    formatted_lines=$(grep -cE "$format_regex" "$log_file" 2>/dev/null || echo "0")
    
    # Count malformed lines (non-empty lines that don't match format)
    malformed_lines=$(grep -cvE "^$|$format_regex" "$log_file" 2>/dev/null || echo "0")
    
    log_step "FORMAT_CHECK" "INFO" "Total lines: $total_lines, Formatted: $formatted_lines, Malformed: $malformed_lines"
    
    if [ "$malformed_lines" -eq 0 ]; then
        log_step "FORMAT_CHECK" "SUCCESS" "All log entries are properly formatted"
    elif [ "$STRICT_MODE" = true ]; then
        log_step "FORMAT_CHECK" "ERROR" "Found $malformed_lines malformed log entries (strict mode)"
        return 1
    else
        log_step "FORMAT_CHECK" "WARNING" "Found $malformed_lines malformed log entries"
    fi
    
    # Show examples of malformed lines if any
    if [ "$malformed_lines" -gt 0 ]; then
        log_step "FORMAT_CHECK" "INFO" "Examples of malformed lines:"
        grep -vE "^$|$format_regex" "$log_file" | head -3 | while read -r line; do
            log_step "FORMAT_CHECK" "INFO" "  $line"
        done
    fi
    
    return 0
}

# Analyze log entry statistics
analyze_log_statistics() {
    local log_file="$1"
    
    log_step "STATS_ANALYSIS" "START" "Analyzing statistics for $(basename "$log_file")"
    
    local start_count success_count error_count warning_count info_count
    start_count=$(grep -c "START" "$log_file" 2>/dev/null || echo "0")
    success_count=$(grep -c "SUCCESS" "$log_file" 2>/dev/null || echo "0") 
    error_count=$(grep -c "ERROR" "$log_file" 2>/dev/null || echo "0")
    warning_count=$(grep -c "WARNING" "$log_file" 2>/dev/null || echo "0")
    info_count=$(grep -c "INFO" "$log_file" 2>/dev/null || echo "0")
    
    local total_entries=$((start_count + success_count + error_count + warning_count + info_count))
    
    log_step "STATS_ANALYSIS" "INFO" "Entry breakdown: START=$start_count, SUCCESS=$success_count, ERROR=$error_count, WARNING=$warning_count, INFO=$info_count"
    
    # Check for workflow consistency (START should roughly match SUCCESS+ERROR)
    local completion_rate=0
    if [ "$start_count" -gt 0 ]; then
        completion_rate=$(((success_count + error_count) * 100 / start_count))
        log_step "STATS_ANALYSIS" "INFO" "Workflow completion rate: $completion_rate% ($((success_count + error_count))/$start_count)"
    fi
    
    # Success rate
    local success_rate=0
    if [ $((success_count + error_count)) -gt 0 ]; then
        success_rate=$((success_count * 100 / (success_count + error_count)))
        log_step "STATS_ANALYSIS" "INFO" "Success rate: $success_rate% ($success_count/$((success_count + error_count)))"
    fi
    
    # Validation checks
    if [ "$total_entries" -eq 0 ]; then
        log_step "STATS_ANALYSIS" "WARNING" "No log entries found in file"
    elif [ "$success_count" -eq 0 ] && [ "$error_count" -eq 0 ]; then
        log_step "STATS_ANALYSIS" "WARNING" "No completion entries (SUCCESS/ERROR) found"
    elif [ "$completion_rate" -lt 50 ] && [ "$start_count" -gt 5 ]; then
        log_step "STATS_ANALYSIS" "WARNING" "Low workflow completion rate: $completion_rate%"
    elif [ "$success_rate" -lt 80 ] && [ $((success_count + error_count)) -gt 5 ]; then
        log_step "STATS_ANALYSIS" "WARNING" "Low success rate: $success_rate%"
    else
        log_step "STATS_ANALYSIS" "SUCCESS" "Log statistics look healthy"
    fi
    
    return 0
}

# Check timestamp consistency
validate_timestamps() {
    local log_file="$1"
    
    log_step "TIMESTAMP_CHECK" "START" "Validating timestamp consistency for $(basename "$log_file")"
    
    # Extract timestamps and check if they're chronological
    local timestamps_file
    timestamps_file=$(mktemp)
    
    grep -oE '\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\]' "$log_file" | \
        sed 's/\[//; s/\]//' > "$timestamps_file"
    
    local total_timestamps out_of_order
    total_timestamps=$(wc -l < "$timestamps_file")
    out_of_order=0
    
    if [ "$total_timestamps" -gt 1 ]; then
        # Check for out-of-order timestamps
        local prev_timestamp current_timestamp
        prev_timestamp=""
        
        while IFS= read -r current_timestamp; do
            if [ -n "$prev_timestamp" ]; then
                # Convert to epoch for comparison
                local prev_epoch current_epoch
                prev_epoch=$(date -d "$prev_timestamp" +%s 2>/dev/null || echo "0")
                current_epoch=$(date -d "$current_timestamp" +%s 2>/dev/null || echo "0")
                
                if [ "$current_epoch" -lt "$prev_epoch" ]; then
                    out_of_order=$((out_of_order + 1))
                    if [ "$out_of_order" -eq 1 ]; then
                        log_step "TIMESTAMP_CHECK" "WARNING" "Out-of-order timestamp detected: $current_timestamp < $prev_timestamp"
                    fi
                fi
            fi
            prev_timestamp="$current_timestamp"
        done < "$timestamps_file"
    fi
    
    rm -f "$timestamps_file"
    
    log_step "TIMESTAMP_CHECK" "INFO" "Total timestamps: $total_timestamps, Out-of-order: $out_of_order"
    
    if [ "$out_of_order" -eq 0 ]; then
        log_step "TIMESTAMP_CHECK" "SUCCESS" "All timestamps are in chronological order"
    else
        local severity="WARNING"
        if [ "$STRICT_MODE" = true ] && [ "$out_of_order" -gt 5 ]; then
            severity="ERROR"
        fi
        log_step "TIMESTAMP_CHECK" "$severity" "Found $out_of_order out-of-order timestamps"
        
        if [ "$severity" = "ERROR" ]; then
            return 1
        fi
    fi
    
    return 0
}

# Check for required workflow patterns
validate_workflow_patterns() {
    local log_file="$1"
    
    log_step "WORKFLOW_CHECK" "START" "Checking workflow patterns for $(basename "$log_file")"
    
    # Check for script initialization pattern
    if grep -q "SCRIPT_INIT.*START" "$log_file"; then
        log_step "WORKFLOW_CHECK" "SUCCESS" "Found script initialization pattern"
    else
        log_step "WORKFLOW_CHECK" "WARNING" "No script initialization pattern found"
    fi
    
    # Check for proper workflow closure
    if grep -q "SCRIPT_INIT.*SUCCESS\|SCRIPT_INIT.*ERROR" "$log_file"; then
        log_step "WORKFLOW_CHECK" "SUCCESS" "Found script completion pattern"  
    else
        log_step "WORKFLOW_CHECK" "WARNING" "No script completion pattern found"
    fi
    
    # Check for step patterns (START followed by SUCCESS/ERROR)
    local start_steps success_error_steps
    start_steps=$(grep -c "START" "$log_file" | head -1)
    success_error_steps=$(grep -cE "(SUCCESS|ERROR)" "$log_file" | head -1)
    
    if [ "$start_steps" -gt 0 ] && [ "$success_error_steps" -gt 0 ]; then
        log_step "WORKFLOW_CHECK" "SUCCESS" "Found proper step patterns (START/SUCCESS|ERROR)"
    elif [ "$start_steps" -eq 0 ]; then
        log_step "WORKFLOW_CHECK" "WARNING" "No START steps found"
    else
        log_step "WORKFLOW_CHECK" "WARNING" "Found START steps but no completion steps"
    fi
    
    return 0
}

# Validate single log file
validate_single_file() {
    local log_file="$1"
    local errors=0
    
    log_step "FILE_VALIDATION" "START" "Validating log file: $log_file"
    
    # Basic file checks
    if [ ! -f "$log_file" ]; then
        log_step "FILE_VALIDATION" "ERROR" "File does not exist: $log_file"
        return 1
    fi
    
    if [ ! -r "$log_file" ]; then
        log_step "FILE_VALIDATION" "ERROR" "File is not readable: $log_file"
        return 1
    fi
    
    local file_size
    file_size=$(du -h "$log_file" | cut -f1)
    log_step "FILE_VALIDATION" "INFO" "File size: $file_size"
    
    # Run validation checks
    validate_log_format "$log_file" || errors=$((errors + 1))
    analyze_log_statistics "$log_file" || errors=$((errors + 1))
    validate_timestamps "$log_file" || errors=$((errors + 1))
    validate_workflow_patterns "$log_file" || errors=$((errors + 1))
    
    if [ "$errors" -eq 0 ]; then
        log_step "FILE_VALIDATION" "SUCCESS" "File validation completed successfully"
    else
        log_step "FILE_VALIDATION" "ERROR" "File validation completed with $errors errors"
    fi
    
    return "$errors"
}

# Validate directory of log files
validate_directory() {
    local log_dir="$1"
    local total_files=0
    local valid_files=0
    
    log_step "DIR_VALIDATION" "START" "Validating log files in directory: $log_dir"
    
    if [ ! -d "$log_dir" ]; then
        log_step "DIR_VALIDATION" "ERROR" "Directory does not exist: $log_dir"
        return 1
    fi
    
    # Find log files
    local log_files
    log_files=$(find "$log_dir" -name "*.log" -type f)
    
    if [ -z "$log_files" ]; then
        log_step "DIR_VALIDATION" "WARNING" "No log files found in directory: $log_dir"
        return 0
    fi
    
    # Validate each file
    while IFS= read -r log_file; do
        total_files=$((total_files + 1))
        
        if validate_single_file "$log_file"; then
            valid_files=$((valid_files + 1))
        fi
        
        echo "" # Blank line between files
    done <<< "$log_files"
    
    log_step "DIR_VALIDATION" "INFO" "Validation summary: $valid_files/$total_files files passed validation"
    
    if [ "$valid_files" -eq "$total_files" ]; then
        log_step "DIR_VALIDATION" "SUCCESS" "All log files passed validation"
        return 0
    else
        local failed_files=$((total_files - valid_files))
        log_step "DIR_VALIDATION" "WARNING" "$failed_files files failed validation"
        
        if [ "$STRICT_MODE" = true ]; then
            log_step "DIR_VALIDATION" "ERROR" "Validation failed in strict mode"
            return 1
        fi
        
        return 0
    fi
}

# Show usage information
show_usage() {
    cat << EOF
Tezos Baker Log Validation Tool

Usage: $0 [target] [options]

Parameters:
  target           Log file or directory to validate [default: logs/]

Options:
  --strict         Enable strict validation mode (fail on warnings)
  --help, -h       Show this help message

Description:
  Validates Tezos baker log files for format compliance, consistency,
  and completeness. Checks timestamp ordering, workflow patterns,
  and entry statistics.

Validation Checks:
  - Log entry format compliance
  - Timestamp chronological ordering
  - Workflow pattern consistency
  - Entry statistics and completion rates
  - File accessibility and basic properties

Examples:
  $0                                    # Validate all logs in logs/
  $0 logs/import_snapshot_2025-09-06.log # Validate specific file
  $0 --strict                          # Strict validation mode
  $0 /var/log/tezos                    # Validate custom directory

Exit codes:
  0  All validations passed
  1  Some validations failed
  2  Configuration or access error
EOF
}

# Main execution
main() {
    # Parse arguments
    parse_arguments "$@"
    
    # Shift processed arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --strict|--help|-h)
                shift
                ;;
            *)
                break
                ;;
        esac
    done
    
    log_system_info
    
    log_step "VALIDATION_CONFIG" "INFO" "Target: $TARGET"
    log_step "VALIDATION_CONFIG" "INFO" "Strict mode: $([ "$STRICT_MODE" = true ] && echo "enabled" || echo "disabled")"
    
    local exit_code=0
    
    if [ -f "$TARGET" ]; then
        # Validate single file
        validate_single_file "$TARGET" || exit_code=1
    elif [ -d "$TARGET" ]; then
        # Validate directory
        validate_directory "$TARGET" || exit_code=1
    else
        log_step "VALIDATION_ERROR" "ERROR" "Target is neither a file nor directory: $TARGET"
        exit_code=2
    fi
    
    if [ "$exit_code" -eq 0 ]; then
        log_step "VALIDATION_COMPLETE" "SUCCESS" "Log validation completed successfully"
    else
        log_step "VALIDATION_COMPLETE" "ERROR" "Log validation completed with errors"
    fi
    
    exit "$exit_code"
}

# Execute main function
main "$@"