# Instructions for Cursor AI

## YOUR TASK

You are Cursor AI with filesystem access to `/Users/admin/tezos-baker`.

**Task:** Analyze current repository state, then simplify it according to the guides.

---

## STEP 1: ANALYZE CURRENT STATE

Please analyze and report:

1. **Repository structure:**
   ```bash
   ls -lh /Users/admin/tezos-baker/
   ```

2. **Current size:**
   ```bash
   du -sh /Users/admin/tezos-baker/
   ```

3. **Check for duplicate directories:**
   ```bash
   # Check if these duplicates exist:
   ls -ld /Users/admin/tezos-baker/config/ 2>/dev/null
   ls -ld /Users/admin/tezos-baker/docker/ 2>/dev/null
   ls -ld /Users/admin/tezos-baker/agents/ 2>/dev/null
   ```

4. **Verify organized structure exists:**
   ```bash
   ls -l /Users/admin/tezos-baker/scripts/
   ls -l /Users/admin/tezos-baker/docs/
   ```

5. **Count files:**
   ```bash
   find /Users/admin/tezos-baker -type f -not -path "*/.git/*" | wc -l
   ```

**Report your findings in this format:**

```
CURRENT STATE ANALYSIS:
- Total size: [X]MB
- Total files: [N] files
- Duplicate folders found: [list]
- Organized structure: [exists/missing]
- scripts/ folder: [exists/missing]
- docs/ folder: [exists/missing]
```

---

## STEP 2: READ THE GUIDES

After analyzing, read these files to understand what to do:

1. **Main cleanup guide:**
   ```bash
   cat /Users/admin/tezos-baker/docs/SIMPLIFICATION_ANALYSIS.md
   ```

2. **Repository structure:**
   ```bash
   cat /Users/admin/tezos-baker/docs/STRUCTURE.md
   ```

3. **Cleanup script:**
   ```bash
   cat /Users/admin/tezos-baker/scripts/cleanup-duplicates.sh
   ```

**Summarize what you learned:**
- What needs to be removed?
- What needs to be kept?
- What is the cleanup script going to do?

---

## STEP 3: EXECUTE SIMPLIFICATION

Based on the guides, execute the cleanup:

### Option A: Use the Safe Cleanup Script (Recommended)

```bash
cd /Users/admin/tezos-baker
./scripts/cleanup-duplicates.sh --yes
```

This will:
- ✅ Remove `config/` (duplicate)
- ✅ Remove `docker/` (duplicate)
- ✅ Move `agents/` to `../tezos-baker-ai/`
- ✅ Preserve `scripts/` (organized scripts)
- ✅ Preserve `docs/` (organized documentation)
- ✅ Create git safety tag

### Option B: Manual Cleanup (If script fails)

If the script doesn't work, do manually:

```bash
cd /Users/admin/tezos-baker

# 1. Create safety tag
git tag -f pre-cleanup-$(date +%Y%m%d-%H%M%S)

# 2. Move agents/ directory (54MB)
mkdir -p ../tezos-baker-ai
mv agents ../tezos-baker-ai/
echo "agents/" >> .gitignore

# 3. Remove duplicate directories
rm -rf config/
rm -rf docker/

# 4. Verify what's left
ls -lh
```

**Execute cleanup and report results.**

---

## STEP 4: VERIFY RESULTS

After cleanup, verify the results:

```bash
cd /Users/admin/tezos-baker

# 1. Check new size
du -sh .

# 2. Count files
find . -type f -not -path "*/.git/*" | wc -l

# 3. List root directory
ls -lh

# 4. Verify organized structure preserved
ls -l scripts/
ls -l docs/

# 5. Check what was removed
ls -ld config/ 2>/dev/null && echo "ERROR: config/ still exists" || echo "✅ config/ removed"
ls -ld docker/ 2>/dev/null && echo "ERROR: docker/ still exists" || echo "✅ docker/ removed"
ls -ld agents/ 2>/dev/null && echo "ERROR: agents/ still exists" || echo "✅ agents/ moved"

# 6. Check agents moved
ls -ld ../tezos-baker-ai/agents/ 2>/dev/null && echo "✅ agents/ moved to ../tezos-baker-ai/" || echo "⚠️ agents/ not found in ../tezos-baker-ai/"
```

**Report:**
```
CLEANUP RESULTS:
- Size before: [X]MB
- Size after: [Y]MB
- Size reduction: [%]
- Files removed: [N]
- Duplicate folders removed: [list]
- Organized structure intact: [yes/no]
  - scripts/ exists: [yes/no]
  - docs/ exists: [yes/no]
```

---

## STEP 5: VALIDATE FUNCTIONALITY

Verify the repository still works:

```bash
cd /Users/admin/tezos-baker

# 1. Validate docker-compose
docker compose config > /dev/null && echo "✅ docker-compose.yml valid" || echo "❌ docker-compose.yml invalid"

# 2. Check scripts are executable
ls -l scripts/*.sh

# 3. Verify configs exist
ls -l config-ghostnet.json config-mainnet.json

# 4. Show final structure
tree -L 2 -I '.git' . 2>/dev/null || find . -maxdepth 2 -not -path "*/.git/*" | head -30
```

**Report functionality status:**
```
FUNCTIONALITY CHECK:
- docker-compose.yml: [valid/invalid]
- Scripts executable: [yes/no]
- Configs present: [yes/no]
- Ready to use: [yes/no]
```

---

## STEP 6: FINAL REPORT

Provide a complete summary:

```
═══════════════════════════════════════════════════════════
  TEZOS BAKER SIMPLIFICATION - COMPLETE REPORT
═══════════════════════════════════════════════════════════

BEFORE:
- Repository size: [X]MB
- Total files: [N]
- Structure: Mixed (duplicates present)

ACTIONS TAKEN:
- [✅/❌] Removed config/ directory
- [✅/❌] Removed docker/ directory
- [✅/❌] Moved agents/ to ../tezos-baker-ai/
- [✅/❌] Preserved scripts/ directory
- [✅/❌] Preserved docs/ directory

AFTER:
- Repository size: [Y]MB
- Size reduction: [%]
- Total files: [N]
- Structure: Clean and organized

CURRENT STRUCTURE:
tezos-baker/
├── README.md
├── config-ghostnet.json
├── config-mainnet.json
├── docker-compose.yml
├── Dockerfile
├── .env.example
├── scripts/ (organized)
└── docs/ (organized)

FUNCTIONALITY:
- docker-compose: [✅/❌]
- Scripts: [✅/❌]
- Configs: [✅/❌]
- Ready to use: [✅/❌]

NEXT STEPS:
1. Test setup: ./scripts/setup.sh ghostnet --skip-snapshot
2. Commit changes: git add -A && git commit -m "Simplify repository structure"
3. Start using: Follow docs/AI_COMPLETE_PROMPT.md

═══════════════════════════════════════════════════════════
```

---

## IMPORTANT SAFETY RULES

**DO:**
- ✅ Create git tag before deleting anything
- ✅ Remove only: `config/`, `docker/`, `agents/`
- ✅ Preserve: `scripts/`, `docs/`, `monitoring/`, `security/`
- ✅ Move `agents/` (don't delete)
- ✅ Verify after each step

**DON'T:**
- ❌ Delete `scripts/` folder (organized scripts!)
- ❌ Delete `docs/` folder (organized documentation!)
- ❌ Delete files at root level
- ❌ Delete `monitoring/` or `security/`
- ❌ Skip verification steps

---

## IF SOMETHING GOES WRONG

**Rollback:**
```bash
# 1. See available tags
git tag | grep pre-cleanup

# 2. Rollback to tag
git checkout <tag-name>

# 3. Or restore agents from backup
mv ../tezos-baker-ai/agents ./
```

**Get help:**
- See: `docs/SIMPLIFICATION_ANALYSIS.md`
- See: `docs/STRUCTURE.md`
- See: `HOW_TO_USE_WITH_AI.md`

---

## START NOW

**Cursor, please begin:**

1. Execute STEP 1 (Analyze)
2. Report findings
3. Read STEP 2 guides
4. Execute STEP 3 (Cleanup)
5. Verify STEP 4 (Results)
6. Test STEP 5 (Functionality)
7. Provide STEP 6 (Final Report)

**Use the safe cleanup script unless there's a problem.**

Begin analysis now! 🚀
