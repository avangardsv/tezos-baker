# Pre-Publication Security Checklist

**Complete this checklist before making your repository public.**

## ✅ Critical Security Checks

### 1. No Secrets in Git History
```bash
# Check if .env was ever committed
git log --all --full-history -- .env
# Should return nothing

# Check for any tz1/tz2/tz3/tz4 addresses in history
git log --all -p | grep -E "tz[1-4][a-zA-Z0-9]{33}"
# Only testnet address (tz1Wp2H3WFGDsKXYJWeYLmJaFeWp51fH1rWi) is OK

# Check for any edsk (secret keys) in history
git log --all -p | grep -i "edsk"
# Should return NOTHING - this would be a critical leak
```

### 2. .gitignore is Comprehensive
```bash
# Verify .gitignore includes:
cat .gitignore
```
Should include:
- [x] `data/` (contains wallet and node data)
- [x] `dal-data/` (contains DAL node data)
- [x] `.env` (environment variables)
- [x] `backups/` (snapshot downloads)
- [x] `*.log` (log files)

### 3. Remove DAL Data from Git
```bash
# DAL data should not be tracked
git rm -r --cached dal-data/
git commit -m "Remove DAL data from tracking"
```

### 4. Verify Clean Working Directory
```bash
git status
# Should show only untracked files in data/, dal-data/, backups/
```

### 5. Check for Personal Information
```bash
# Search for email addresses
git log | grep -E "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"

# Search for IP addresses (excluding localhost/docker)
git log --all -p | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | grep -v "127.0.0.1\|0.0.0.0"
```

## ✅ Documentation Checks

### 6. README.md Warnings
- [x] Clear "Educational Only" warning added
- [x] "DO NOT use for production" disclaimer
- [x] Link to TezBake for production use
- [x] Lists security limitations

### 7. LICENSE File
- [x] MIT License with educational disclaimer added
- [x] Disclaimer about testnet-only use

### 8. CONTRIBUTING.md
- [x] Clear contribution guidelines
- [x] Scope limitations (testnet only)

## ✅ Repository Configuration

### 9. GitHub Settings (After Publishing)
- [ ] Add repository description: "Educational Tezos baker setup for Ghostnet testnet - Learn baking fundamentals"
- [ ] Add topics: `tezos`, `blockchain`, `baker`, `ghostnet`, `educational`, `docker`, `learning`
- [ ] Enable Issues
- [ ] Enable Discussions (optional, for Q&A)
- [ ] Add README badge: "⚠️ Testnet Only - Not for Production"

### 10. README Badges (Optional)
Add to top of README:
```markdown
![Testnet Only](https://img.shields.io/badge/network-ghostnet-orange)
![Educational](https://img.shields.io/badge/purpose-learning-blue)
![License](https://img.shields.io/badge/license-MIT-green)
```

## ✅ Final Verification

### 11. Fresh Clone Test
```bash
# Clone to new directory and verify setup works
cd /tmp
git clone <your-repo-url> test-clone
cd test-clone
cp .env.example .env
# Edit .env with test values
npm run setup
# Verify no errors
```

### 12. Review All Committed Files
```bash
# List all tracked files
git ls-files

# Manually review each script for:
# - No hardcoded passwords
# - No personal information
# - No production secrets
# - No sensitive IPs/domains (except public Tezos endpoints)
```

## 🚀 Ready to Publish

Once all checks pass:

1. **Commit all changes:**
   ```bash
   git add .gitignore LICENSE CONTRIBUTING.md PUBLISHING-CHECKLIST.md
   git commit -m "Prepare repository for public release"
   ```

2. **Push to GitHub:**
   ```bash
   git push origin main
   ```

3. **Make Repository Public:**
   - Go to GitHub repository Settings
   - Scroll to "Danger Zone"
   - Click "Change visibility"
   - Select "Make public"
   - Confirm

4. **Announce (Optional):**
   - Share on Tezos community forums
   - Reddit r/tezos
   - Twitter/X with #Tezos hashtag
   - Tezos Discord/Telegram

## ⚠️ If You Find a Problem After Publishing

**If you accidentally committed secrets:**

1. **DO NOT just delete the file** - it remains in git history
2. **Immediately rotate/change any exposed credentials**
3. **Use git filter-branch or BFG Repo-Cleaner to remove from history**
4. **Force push (this breaks forks, but necessary for security)**

```bash
# Emergency secret removal (example)
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch path/to/secret/file' \
  --prune-empty --tag-name-filter cat -- --all

git push origin --force --all
```

## 📧 Questions?

If unsure about any security aspect, ask in:
- Tezos Stack Exchange
- r/tezos subreddit
- Tezos Bakers Telegram
- Open a draft PR to get feedback before publishing
