#!/usr/bin/env bash

# Tezos Baker - Key Backup Script
# Creates secure backups of Tezos keys and identity files
#
# Usage: ./backup_keys.sh [account_alias] [--output-dir <dir>] [--encrypt]
#   account_alias: Specific account to backup (optional, defaults to all)
#   --output-dir: Custom backup directory (default: ./backups)
#   --encrypt: Encrypt backups with GPG (recommended)

set -euo pipefail

# Source logging library
source "$(dirname "$0")/lib/log.sh"

# Configuration
ACCOUNT_ALIAS="${1:-all}"
CONTAINER_NAME="tezos-node"
DEFAULT_BACKUP_DIR="./backups"
BACKUP_DIR="$DEFAULT_BACKUP_DIR"
ENCRYPT_BACKUP=false
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Initialize script logging
log_script_start "Backup Tezos keys for $ACCOUNT_ALIAS"

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --output-dir)
                BACKUP_DIR="$2"
                shift 2
                ;;
            --encrypt)
                ENCRYPT_BACKUP=true
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

# Validate parameters and setup
validate_setup() {
    log_step "VALIDATION" "START" "Validating backup configuration"
    
    # Create backup directory
    if [ ! -d "$BACKUP_DIR" ]; then
        log_step "VALIDATION" "INFO" "Creating backup directory: $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
    fi
    
    # Check write permissions
    if [ ! -w "$BACKUP_DIR" ]; then
        log_step "VALIDATION" "ERROR" "Cannot write to backup directory: $BACKUP_DIR"
        exit 1
    fi
    
    # Check encryption prerequisites
    if [ "$ENCRYPT_BACKUP" = true ]; then
        if ! command_exists "gpg"; then
            log_step "VALIDATION" "ERROR" "GPG is required for encryption but not found"
            exit 1
        fi
        
        # Check for GPG keys
        if ! gpg --list-secret-keys >/dev/null 2>&1; then
            log_step "VALIDATION" "WARNING" "No GPG keys found. Generate with: gpg --gen-key"
            log_step "VALIDATION" "ERROR" "Cannot encrypt without GPG keys"
            exit 1
        fi
    fi
    
    log_step "VALIDATION" "SUCCESS" "Backup directory: $BACKUP_DIR"
    log_step "VALIDATION" "SUCCESS" "Encryption: $([ "$ENCRYPT_BACKUP" = true ] && echo "enabled" || echo "disabled")"
}

# Check prerequisites
check_prerequisites() {
    log_step "PREREQUISITES" "START" "Checking required tools and services"
    
    local required_commands=("docker" "tar")
    validate_prerequisites "${required_commands[@]}"
    
    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        log_step "PREREQUISITES" "ERROR" "Docker daemon is not running"
        exit 1
    fi
    
    # Check if container exists
    if ! docker ps -a --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        log_step "PREREQUISITES" "ERROR" "Container '$CONTAINER_NAME' does not exist"
        log_step "PREREQUISITES" "INFO" "Start the node first or create the container"
        exit 1
    fi
    
    log_step "PREREQUISITES" "SUCCESS" "Container '$CONTAINER_NAME' found"
}

# List available accounts
list_accounts() {
    log_step "ACCOUNT_LIST" "START" "Discovering available accounts"
    
    local accounts
    if accounts=$(docker exec "$CONTAINER_NAME" tezos-client list known addresses 2>/dev/null | grep -E "^[a-zA-Z0-9_]+:" | cut -d: -f1); then
        if [ -n "$accounts" ]; then
            log_step "ACCOUNT_LIST" "SUCCESS" "Found accounts: $(echo "$accounts" | tr '\n' ' ')"
            echo "$accounts"
        else
            log_step "ACCOUNT_LIST" "WARNING" "No accounts found in wallet"
            echo ""
        fi
    else
        log_step "ACCOUNT_LIST" "ERROR" "Failed to list accounts"
        exit 1
    fi
}

# Backup specific account
backup_account() {
    local account="$1"
    local backup_file="$BACKUP_DIR/tezos_keys_${account}_${TIMESTAMP}"
    
    log_step "BACKUP_ACCOUNT" "START" "Backing up account: $account"
    
    # Check if account exists
    if ! docker exec "$CONTAINER_NAME" tezos-client show address "$account" >/dev/null 2>&1; then
        log_step "BACKUP_ACCOUNT" "ERROR" "Account '$account' not found"
        return 1
    fi
    
    # Get account information
    local address secret_key public_key
    if address=$(docker exec "$CONTAINER_NAME" tezos-client show address "$account" --show-secret 2>/dev/null | grep "Hash:" | awk '{print $2}'); then
        log_step "BACKUP_ACCOUNT" "INFO" "Account address: $address"
    fi
    
    # Create account backup JSON
    local account_data
    account_data=$(cat << EOF
{
  "account_alias": "$account",
  "address": "$address",
  "backup_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "network": "$(docker exec "$CONTAINER_NAME" cat ~/.tezos-client/config 2>/dev/null | jq -r '.network // "unknown"' 2>/dev/null || echo 'unknown')",
  "backup_version": "1.0"
}
EOF
)
    
    # Export keys
    log_step "BACKUP_ACCOUNT" "INFO" "Exporting keys for $account"
    if docker exec "$CONTAINER_NAME" tezos-client export keys "$account" --output "/tmp/${account}_keys.json" 2>/dev/null; then
        
        # Copy keys from container
        docker cp "$CONTAINER_NAME:/tmp/${account}_keys.json" "${backup_file}_keys.json"
        
        # Create metadata file
        echo "$account_data" > "${backup_file}_metadata.json"
        
        # Create combined archive
        tar -czf "${backup_file}.tar.gz" -C "$BACKUP_DIR" \
            "$(basename "${backup_file}_keys.json")" \
            "$(basename "${backup_file}_metadata.json")"
        
        # Clean up individual files
        rm -f "${backup_file}_keys.json" "${backup_file}_metadata.json"
        
        # Clean up container temp file
        docker exec "$CONTAINER_NAME" rm -f "/tmp/${account}_keys.json"
        
        log_step "BACKUP_ACCOUNT" "SUCCESS" "Account backup created: $(basename "${backup_file}.tar.gz")"
        echo "${backup_file}.tar.gz"
        
    else
        log_step "BACKUP_ACCOUNT" "ERROR" "Failed to export keys for account: $account"
        return 1
    fi
}

# Backup node identity
backup_identity() {
    local backup_file="$BACKUP_DIR/tezos_identity_${TIMESTAMP}.tar.gz"
    
    log_step "BACKUP_IDENTITY" "START" "Backing up node identity"
    
    # Copy identity files from container
    local temp_dir
    temp_dir=$(mktemp -d)
    
    if docker cp "$CONTAINER_NAME:/.tezos-node/identity.json" "$temp_dir/" 2>/dev/null; then
        log_step "BACKUP_IDENTITY" "INFO" "Identity file found"
        
        # Create identity metadata
        local identity_data
        identity_data=$(cat << EOF
{
  "backup_type": "node_identity",
  "backup_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "node_container": "$CONTAINER_NAME",
  "backup_version": "1.0"
}
EOF
)
        
        echo "$identity_data" > "$temp_dir/identity_metadata.json"
        
        # Create archive
        tar -czf "$backup_file" -C "$temp_dir" identity.json identity_metadata.json
        
        rm -rf "$temp_dir"
        
        log_step "BACKUP_IDENTITY" "SUCCESS" "Identity backup created: $(basename "$backup_file")"
        echo "$backup_file"
    else
        log_step "BACKUP_IDENTITY" "WARNING" "No identity file found (node may not be initialized)"
        rm -rf "$temp_dir"
        return 1
    fi
}

# Encrypt backup file
encrypt_backup() {
    local backup_file="$1"
    
    if [ "$ENCRYPT_BACKUP" = true ]; then
        log_step "ENCRYPTION" "START" "Encrypting backup: $(basename "$backup_file")"
        
        # Get default GPG recipient
        local recipient
        if recipient=$(gpg --list-secret-keys --keyid-format SHORT | grep uid | head -1 | sed 's/.*<\(.*\)>.*/\1/' 2>/dev/null); then
            log_step "ENCRYPTION" "INFO" "Using GPG recipient: $recipient"
            
            # Encrypt the file
            if gpg --trust-model always --encrypt -r "$recipient" --output "${backup_file}.gpg" "$backup_file" 2>/dev/null; then
                # Remove unencrypted file
                rm -f "$backup_file"
                log_step "ENCRYPTION" "SUCCESS" "Backup encrypted: $(basename "${backup_file}.gpg")"
                echo "${backup_file}.gpg"
            else
                log_step "ENCRYPTION" "ERROR" "Failed to encrypt backup file"
                exit 1
            fi
        else
            log_step "ENCRYPTION" "ERROR" "No GPG recipient found"
            exit 1
        fi
    else
        echo "$backup_file"
    fi
}

# Verify backup integrity
verify_backup() {
    local backup_file="$1"
    
    log_step "VERIFICATION" "START" "Verifying backup integrity"
    
    if [ ! -f "$backup_file" ]; then
        log_step "VERIFICATION" "ERROR" "Backup file not found: $backup_file"
        return 1
    fi
    
    local file_size
    file_size=$(du -h "$backup_file" | cut -f1)
    log_step "VERIFICATION" "INFO" "Backup file size: $file_size"
    
    # Test archive integrity
    if [[ "$backup_file" == *.tar.gz ]]; then
        if tar -tzf "$backup_file" >/dev/null 2>&1; then
            log_step "VERIFICATION" "SUCCESS" "Archive integrity verified"
        else
            log_step "VERIFICATION" "ERROR" "Archive integrity check failed"
            return 1
        fi
    elif [[ "$backup_file" == *.gpg ]]; then
        if gpg --list-packets "$backup_file" >/dev/null 2>&1; then
            log_step "VERIFICATION" "SUCCESS" "GPG file integrity verified"
        else
            log_step "VERIFICATION" "ERROR" "GPG file integrity check failed"
            return 1
        fi
    fi
    
    log_step "VERIFICATION" "SUCCESS" "Backup verification completed"
}

# Create backup summary
create_summary() {
    local backup_files=("$@")
    local summary_file="$BACKUP_DIR/backup_summary_${TIMESTAMP}.txt"
    
    log_step "SUMMARY" "START" "Creating backup summary"
    
    cat > "$summary_file" << EOF
Tezos Baker Key Backup Summary
==============================
Date: $(date)
Host: $(hostname)
User: $(whoami)
Container: $CONTAINER_NAME

Backup Configuration:
- Target: $ACCOUNT_ALIAS
- Output Directory: $BACKUP_DIR
- Encryption: $([ "$ENCRYPT_BACKUP" = true ] && echo "enabled" || echo "disabled")

Created Files:
EOF
    
    for file in "${backup_files[@]}"; do
        if [ -f "$file" ]; then
            local size
            size=$(du -h "$file" | cut -f1)
            echo "- $(basename "$file") ($size)" >> "$summary_file"
        fi
    done
    
    cat >> "$summary_file" << EOF

Security Notes:
- Store backups in a secure location
- Test restore procedures regularly
- Keep backups separate from production systems
- Consider offline storage for long-term backups

Restore Instructions:
1. Extract backup: tar -xzf <backup_file>
2. Import keys: tezos-client import keys <alias> <key_file>
3. Verify: tezos-client show address <alias>
EOF
    
    log_step "SUMMARY" "SUCCESS" "Summary created: $(basename "$summary_file")"
}

# Show usage information
show_usage() {
    cat << EOF
Tezos Key Backup Tool

Usage: $0 [account_alias] [options]

Parameters:
  account_alias    Specific account to backup (optional, default: all accounts)

Options:
  --output-dir <dir>   Custom backup directory [default: ./backups]
  --encrypt           Encrypt backups with GPG (recommended)
  --help, -h          Show this help message

Examples:
  $0                           # Backup all accounts to ./backups
  $0 alice                     # Backup only 'alice' account
  $0 --encrypt                 # Backup all accounts with encryption
  $0 alice --output-dir /secure/backups --encrypt

Security Recommendations:
  - Always use encryption for production keys
  - Store backups offline and in multiple locations
  - Test restore procedures regularly
  - Keep backups separate from production systems

Output Files:
  - tezos_keys_<account>_<timestamp>.tar.gz
  - tezos_identity_<timestamp>.tar.gz
  - backup_summary_<timestamp>.txt
  - (Add .gpg extension if encrypted)

Exit codes:
  0  Backup completed successfully
  1  Backup failed
  2  Configuration error
EOF
}

# Main execution
main() {
    # Parse arguments first
    parse_arguments "$@"
    
    # Shift processed arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --output-dir|--encrypt|--help|-h)
                shift
                ;;
            *)
                break
                ;;
        esac
    done
    
    log_system_info
    
    validate_setup
    check_prerequisites
    
    local backup_files=()
    
    # Backup node identity first
    if identity_backup=$(backup_identity); then
        identity_backup=$(encrypt_backup "$identity_backup")
        verify_backup "$identity_backup"
        backup_files+=("$identity_backup")
    fi
    
    # Backup accounts
    if [ "$ACCOUNT_ALIAS" = "all" ]; then
        log_step "BACKUP_ALL" "START" "Backing up all accounts"
        
        local accounts
        accounts=$(list_accounts)
        
        if [ -n "$accounts" ]; then
            while IFS= read -r account; do
                if account_backup=$(backup_account "$account"); then
                    account_backup=$(encrypt_backup "$account_backup")
                    verify_backup "$account_backup"
                    backup_files+=("$account_backup")
                fi
            done <<< "$accounts"
        else
            log_step "BACKUP_ALL" "WARNING" "No accounts found to backup"
        fi
    else
        # Backup specific account
        if account_backup=$(backup_account "$ACCOUNT_ALIAS"); then
            account_backup=$(encrypt_backup "$account_backup")
            verify_backup "$account_backup"
            backup_files+=("$account_backup")
        fi
    fi
    
    # Create summary
    if [ ${#backup_files[@]} -gt 0 ]; then
        create_summary "${backup_files[@]}"
        
        log_step "BACKUP_COMPLETE" "SUCCESS" "Backup completed successfully"
        log_step "BACKUP_COMPLETE" "INFO" "Files created: ${#backup_files[@]}"
        log_step "BACKUP_COMPLETE" "INFO" "Location: $BACKUP_DIR"
        
        if [ "$ENCRYPT_BACKUP" = false ]; then
            log_step "BACKUP_COMPLETE" "WARNING" "Backups are not encrypted! Consider using --encrypt for production"
        fi
    else
        log_step "BACKUP_COMPLETE" "ERROR" "No backups were created"
        exit 1
    fi
}

# Execute main function
main "$@"