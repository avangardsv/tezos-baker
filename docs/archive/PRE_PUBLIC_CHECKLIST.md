# Pre-Publication Security Checklist

Before making this repository public, verify:

## Critical Security Checks

- [ ] Run: `git log --all --full-history --source -- data/ .env backups/`
  - Verify NO sensitive files in git history

- [ ] Run: `git log -p | grep -i "password\|secret\|private"`
  - Verify NO secrets in commit messages or diffs

- [ ] Search for your baker address:
  ```bash
  grep -r "tz1[a-zA-Z0-9]*" . --include="*.md" --include="*.json" --include="*.sh"
  ```
  - Replace any real addresses with `tz1XXXXX...` placeholders

- [ ] Search for IP addresses:
  ```bash
  grep -r "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" . --include="*.md" --include="*.sh"
  ```
  - Replace real IPs with `X.X.X.X` or `127.0.0.1`

- [ ] Review commit history:
  ```bash
  git log --oneline --all
  ```
  - Check commit messages don't reveal sensitive info

- [ ] Check .gitignore is comprehensive:
  ```bash
  cat .gitignore
  ```
  - Ensure data/, .env, backups/, docs/ are excluded

## Sanitization Tasks

- [ ] Remove or redact any server hostnames
- [ ] Remove any API keys or tokens from commit history
- [ ] Replace example outputs with generic data
- [ ] Check scripts don't contain hardcoded credentials

## Documentation Updates

- [ ] Add clear WARNING in README:
  ```markdown
  ⚠️ **SECURITY WARNING**: This is a testnet configuration.
  For mainnet, additional security hardening is required:
  - Use hardware wallet for keys
  - Configure strict RPC ACL
  - Enable firewall rules
  - Use VPN or private network
  - Review all security documentation
  ```

- [ ] Add LICENSE file (MIT, Apache 2.0, etc.)

- [ ] Add SECURITY.md with responsible disclosure policy

- [ ] Add clear "This is for educational purposes" disclaimer

## If Sensitive Data Found in History

If you find ANY sensitive data in git history, you have two options:

### Option 1: Clean History (Complex)
```bash
# Use git filter-branch or BFG Repo-Cleaner
# WARNING: This rewrites history - all collaborators must re-clone
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch data/.env" \
  --prune-empty --tag-name-filter cat -- --all
```

### Option 2: Start Fresh (Simple, Recommended)
```bash
# Create new repo with clean history
mkdir tezos-baker-public
cp -r scripts package.json README.md .gitignore .env.example tezos-baker-public/
cd tezos-baker-public
git init
git add .
git commit -m "Initial public release - Tezos baker setup for Ghostnet"
```

## Post-Publication Monitoring

After making public:

- [ ] Enable GitHub security alerts
- [ ] Watch for issues reporting security problems
- [ ] Monitor forks (people may accidentally commit sensitive data)
- [ ] Set up dependabot for dependency updates

## For Mainnet Migration

If this baker moves to mainnet:

- [ ] **IMMEDIATELY make repo private**
- [ ] Review all public commits for leaked info
- [ ] Change all credentials/keys
- [ ] Use separate infrastructure (don't reuse servers)
- [ ] Implement all production security measures

---

**Remember**: Once data is public on GitHub, consider it **permanently public** even if you delete the repo. Git history is distributed - anyone who cloned it keeps a copy.
