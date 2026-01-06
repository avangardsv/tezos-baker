# AI Safety Recommendations for Cursor

**Date**: 2026-01-03  
**Status**: Recommendations for Implementation

---

## Current Safety Measures ✅

1. **CLI Configuration** (`.cursor/cli.json`)
   - Git write commands restricted
   - Dangerous system commands restricted (`rm`, `dd`, `shutdown`, etc.)
   - Unsafe script execution patterns blocked

2. **VS Code Settings** (`.vscode/settings.json`)
   - Git confirmations required
   - Smart commits disabled
   - Force push confirmations enabled

3. **Git Pre-commit Hook** (`.git/hooks/pre-commit`)
   - Editor-initiated commit detection
   - Manual confirmation required

---

## Recommended Additional Safety Measures

### 1. Enhanced Command Restrictions

**Add to `.cursor/cli.json` deny list:**

```json
// Additional dangerous patterns
"Shell(find . -delete)",
"Shell(find . -exec rm)",
"Shell(truncate -s 0)",
"Shell(> /dev/sd*)",
"Shell(mv */ /root)",
"Shell(mv */ /bin)",
"Shell(mv */ /usr)",
"Shell(mv */ /etc)",
"Shell(sudo su)",
"Shell(sudo -i)",
"Shell(sudo -s)",
"Shell(sudo passwd)",
"Shell(history -c)",
"Shell(export AWS_ACCESS_KEY)",
"Shell(export GITHUB_TOKEN)",
"Shell(export TEZOS_SECRET_KEY)",
"Shell(export *SECRET*)",
"Shell(export *PASSWORD*)",
"Shell(export *KEY*)",
"Shell(export *TOKEN*)",
"Shell(export *CREDENTIAL*)",
"Shell(echo *SECRET* >>)",
"Shell(echo *PASSWORD* >>)",
"Shell(echo *KEY* >>)",
"Shell(git push --force)",
"Shell(git push -f)",
"Shell(git push origin --delete)",
"Shell(git push origin :*)",
"Shell(git filter-branch)",
"Shell(git filter-repo)",
"Shell(npm publish)",
"Shell(npm unpublish)",
"Shell(docker rm -f)",
"Shell(docker rmi -f)",
"Shell(docker system prune -a)",
"Shell(podman rm -f)",
"Shell(podman rmi -f)",
"Shell(podman system prune -a)"
```

### 2. Project-Specific Protections (Tezos Baker)

**Critical files/directories to protect:**
- `data/identity.json` - Contains baker identity
- `data/context/` - Blockchain state
- `data/store/` - Blockchain data
- `.env` - Environment variables (if exists)
- `config-ghostnet.json` - Network configuration
- `backups/` - Backup snapshots

**Add to `.cursor/cli.json` deny list:**
```json
"Shell(rm data/identity.json)",
"Shell(rm -rf data/context)",
"Shell(rm -rf data/store)",
"Shell(rm config-*.json)",
"Shell(rm backups/*)",
"Shell(mv data/identity.json)",
"Shell(cp data/identity.json)"
```

### 3. Environment Variable Protection

**Create `.cursor/.env-protection.json`** (if Cursor supports this):
- Block commands that expose secrets
- Block commands that modify `.env` files
- Block commands that print environment variables containing sensitive data

**Add to VS Code settings:**
```json
{
  "files.associations": {
    ".env": "properties",
    ".env.*": "properties"
  },
  "files.exclude": {
    "**/.env.local": true,
    "**/.env.production": true
  }
}
```

### 4. File System Monitoring

**Create a script to monitor critical files:**
```bash
#!/bin/bash
# scripts/monitor-critical-files.sh
# Monitors critical files for unauthorized changes

CRITICAL_FILES=(
  "data/identity.json"
  "config-ghostnet.json"
  ".cursor/cli.json"
  ".vscode/settings.json"
)

for file in "${CRITICAL_FILES[@]}"; do
  if [ -f "$file" ]; then
    # Check if file was modified in last 5 minutes
    if [ $(find "$file" -mmin -5 | wc -l) -gt 0 ]; then
      echo "⚠️  WARNING: $file was recently modified"
      # Could send alert here
    fi
  fi
done
```

### 5. Enhanced Pre-commit Hook

**Improve `.git/hooks/pre-commit` to:**
- Detect AI-generated commit messages
- Check for sensitive data in commits
- Prevent commits to protected branches
- Require explicit user confirmation

**Enhanced version:**
```bash
#!/bin/bash
# Enhanced pre-commit hook

# Check for sensitive data patterns
SENSITIVE_PATTERNS=(
  "password.*="
  "secret.*="
  "api.*key.*="
  "private.*key"
  "-----BEGIN.*PRIVATE KEY-----"
)

for pattern in "${SENSITIVE_PATTERNS[@]}"; do
  if git diff --cached | grep -qi "$pattern"; then
    echo "❌ ERROR: Potential sensitive data detected: $pattern"
    echo "Please review your changes before committing."
    exit 1
  fi
done

# Check for large files (>10MB)
LARGE_FILES=$(git diff --cached --name-only | xargs ls -lh 2>/dev/null | awk '$5 ~ /[0-9]+M/ && $5+0 > 10 {print $9}')
if [ -n "$LARGE_FILES" ]; then
  echo "⚠️  WARNING: Large files detected:"
  echo "$LARGE_FILES"
  read -p "Continue anyway? (yes/no): " -r
  if [[ ! $REPLY =~ ^yes$ ]]; then
    exit 1
  fi
fi

# Existing Cursor/VS Code detection
if [ -n "$CURSOR_PID" ] || [ -n "$VSCODE_PID" ]; then
  echo "⚠️  WARNING: Commit initiated from Cursor/VS Code"
  read -p "Type 'yes' to continue: " -n 3 -r
  echo
  if [[ ! $REPLY =~ ^yes$ ]]; then
    echo "❌ Commit cancelled"
    exit 1
  fi
fi

exit 0
```

### 6. Backup Strategy

**Automated backups before AI operations:**
```bash
#!/bin/bash
# scripts/pre-ai-backup.sh
# Run before allowing AI to make changes

BACKUP_DIR="backups/pre-ai-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup critical files
cp -r data/identity.json "$BACKUP_DIR/" 2>/dev/null
cp config-*.json "$BACKUP_DIR/" 2>/dev/null
cp .cursor/cli.json "$BACKUP_DIR/" 2>/dev/null
cp .vscode/settings.json "$BACKUP_DIR/" 2>/dev/null

# Git stash current changes
git stash push -m "Pre-AI backup $(date +%Y%m%d-%H%M%S)"

echo "✅ Backup created: $BACKUP_DIR"
```

### 7. Cursor Rules File (Optional but Recommended)

**Create `.cursorrules` for explicit AI behavior:**
```
# Cursor AI Safety Rules

## Critical Restrictions
- NEVER execute git write commands automatically
- NEVER delete files in data/ directory
- NEVER modify data/identity.json
- NEVER expose secrets or API keys
- ALWAYS ask for confirmation before:
  - Modifying configuration files
  - Running docker/podman commands
  - Installing packages
  - Modifying system files

## Tezos-Specific Rules
- NEVER modify data/identity.json (baker identity)
- NEVER delete data/context/ or data/store/
- NEVER modify config-ghostnet.json without explicit permission
- ALWAYS backup before making changes to critical files

## Best Practices
- Suggest commands as text, don't execute automatically
- Explain what each command does before suggesting
- Warn about potential side effects
- Provide rollback instructions
```

### 8. Network Security

**Add restrictions for network operations:**
```json
// In .cursor/cli.json deny list:
"Shell(nc -l)",
"Shell(netcat -l)",
"Shell(ssh -R)",
"Shell(ssh -L)",
"Shell(ssh -D)",
"Shell(ssh-copy-id)",
"Shell(scp)",
"Shell(rsync --delete)"
```

### 9. Package Management Safety

**Restrict dangerous npm/pip operations:**
```json
// In .cursor/cli.json deny list:
"Shell(npm install -g)",
"Shell(pip install --user)",
"Shell(pip install --upgrade)",
"Shell(npm audit fix --force)",
"Shell(npm update -g)"
```

### 10. Docker/Podman Safety

**Add container safety restrictions:**
```json
// In .cursor/cli.json deny list:
"Shell(docker exec -it)",
"Shell(docker run --privileged)",
"Shell(docker run --rm -v /:/host)",
"Shell(podman run --privileged)",
"Shell(podman run --rm -v /:/host)"
```

---

## Implementation Priority

### 🔴 High Priority (Implement First)
1. Enhanced pre-commit hook (sensitive data detection)
2. Project-specific file protections (identity.json, data/)
3. Force push restrictions
4. Environment variable protection patterns

### 🟡 Medium Priority
5. File system monitoring script
6. Backup automation
7. Network operation restrictions
8. Package management restrictions

### 🟢 Low Priority (Nice to Have)
9. Docker/Podman enhanced restrictions
10. Advanced monitoring and alerting

---

## Testing Your Safety Configuration

### Test 1: Git Write Commands
```bash
# AI should NOT be able to execute:
git add .
git commit -m "test"
git push
```

### Test 2: Dangerous Commands
```bash
# AI should NOT be able to execute:
rm -rf data/
rm data/identity.json
dd if=/dev/zero of=/dev/sda
```

### Test 3: Sensitive Data
```bash
# Pre-commit hook should block:
git commit -m "password=secret123"
```

### Test 4: Critical Files
```bash
# AI should NOT be able to:
rm data/identity.json
mv data/identity.json /tmp/
```

---

## Monitoring & Alerts

### Check Recent Changes
```bash
# Monitor recent file modifications
find . -type f -mmin -30 -not -path "./.git/*" -not -path "./node_modules/*"
```

### Git Activity Log
```bash
# Check recent git operations
git reflog | head -20
```

### Critical File Integrity
```bash
# Verify critical files exist and haven't been modified
ls -la data/identity.json
ls -la config-ghostnet.json
ls -la .cursor/cli.json
```

---

## Recovery Procedures

### If AI Made Unwanted Changes

1. **Check git status:**
   ```bash
   git status
   git diff
   ```

2. **Restore from backup:**
   ```bash
   # Find latest backup
   ls -lt backups/pre-ai-*/
   
   # Restore files
   cp backups/pre-ai-YYYYMMDD-HHMMSS/data/identity.json data/
   ```

3. **Revert git changes:**
   ```bash
   git stash list
   git stash pop stash@{N}
   # OR
   git reset --hard HEAD
   ```

4. **Check for sensitive data exposure:**
   ```bash
   git log --all --source --grep="password\|secret\|key" -i
   ```

---

## Summary

**Current Protection Level**: 🟡 Medium
- Git write commands: ✅ Restricted
- Dangerous system commands: ✅ Restricted
- Pre-commit hook: ✅ Active
- Project-specific protections: ❌ Not implemented

**Recommended Next Steps**:
1. Add project-specific file protections
2. Enhance pre-commit hook with sensitive data detection
3. Add force push restrictions
4. Implement backup automation
5. Add file monitoring

**Estimated Implementation Time**: 1-2 hours

---

**Last Updated**: 2026-01-03

