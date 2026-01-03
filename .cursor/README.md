# Cursor Git Restrictions Configuration

This directory contains configuration to restrict Cursor AI from automatically executing git write operations.

## Files Configured

### 1. `.cursorrules`
AI behavior rules that instruct Cursor to:
- NOT execute `git commit`, `git push`, or `git add` commands
- Only suggest commands for user to run manually
- Require explicit user approval for all write operations

### 2. `.vscode/settings.json`
VS Code/Cursor settings that:
- Disable automatic git operations
- Require confirmation for all git write actions
- Prevent smart commits and auto-stashing
- Force user interaction for all git operations

### 3. `.git/hooks/pre-commit`
Git hook that:
- Detects editor-initiated commits
- Requires manual confirmation before proceeding
- Adds extra safety layer

## How It Works

### When AI suggests changes:

**❌ BLOCKED Behavior:**
```
AI: "Let me commit these changes for you"
[Automatically runs: git commit -m "..."]
```

**✅ ALLOWED Behavior:**
```
AI: "To commit these changes, run:"

git add file.txt
git commit -m "Description of changes"
git push origin main
```

### User Must Manually Execute

All git write commands must be:
1. Shown to user as text
2. Reviewed by user
3. Manually typed/copied by user
4. Executed in terminal by user

## Testing the Configuration

### Test 1: Try to commit from Cursor
1. Make changes to a file
2. Try to commit using Cursor UI
3. Should prompt for confirmation

### Test 2: Ask AI to commit
1. Ask: "Please commit these changes"
2. AI should respond with command to run, not execute it

### Test 3: Manual commit
```bash
# This should work normally
git add file.txt
git commit -m "Manual commit"
git push origin main
```

## Override (Emergency Use)

If you need to temporarily disable restrictions:

### Bypass hook:
```bash
git commit --no-verify -m "Emergency commit"
```

### Bypass Cursor rules:
Temporarily rename `.cursorrules` to `.cursorrules.disabled`

## Maintenance

### Update rules:
Edit `.cursorrules` to modify AI behavior

### Update settings:
Edit `.vscode/settings.json` for Cursor/VS Code settings

### Update hook:
Edit `.git/hooks/pre-commit` for git-level restrictions

## Verification

Check if restrictions are active:

```bash
# Check hook is executable
ls -la .git/hooks/pre-commit

# Check cursorrules exists
cat .cursorrules

# Check VS Code settings
cat .vscode/settings.json | grep "git."
```

All should return valid content.
