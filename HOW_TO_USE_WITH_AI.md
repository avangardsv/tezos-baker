# How to Use This Repository with Another AI

This guide explains how to hand off the Tezos Baker setup to a less advanced AI assistant.

---

## 📋 Quick Instructions

### Step 1: Copy the Complete Prompt

The file **`docs/AI_COMPLETE_PROMPT.md`** contains everything an AI needs.

**Copy it:**
```bash
cat docs/AI_COMPLETE_PROMPT.md
```

Or open it and copy the entire contents (~22KB, 931 lines).

### Step 2: Give to Another AI

**Paste this to the AI:**

```
I'm giving you a complete prompt to set up a Tezos baker on testnet (Ghostnet).

Read the entire prompt below carefully and follow the instructions.

The prompt contains:
- Current repository state
- Step-by-step setup instructions
- Troubleshooting guide
- All commands with expected outputs
- Configuration explanations

Here is the complete prompt:

[PASTE ENTIRE CONTENTS OF docs/AI_COMPLETE_PROMPT.md HERE]

---

After reading the prompt, please:
1. Confirm you understand the current repository structure
2. Ask me which option I want (Option 1: Quick test, or Option 2: Clean simplification)
3. Then execute the steps for that option
```

---

## 📝 Alternative: Shorter Prompt

If the AI has token limits, use this condensed version:

```
You are helping set up a Tezos baker for Ghostnet testnet.

CURRENT REPOSITORY STRUCTURE:
- Scripts are in: scripts/ folder
- Documentation is in: docs/ folder
- Configs at root: config-ghostnet.json, docker-compose.yml, Dockerfile
- Duplicates to remove: config/, docker/, agents/ (54MB)

TASK: Run Ghostnet testnet baker in 3 commands

COMMANDS:
cd /Users/admin/tezos-baker

# 1. Setup
./scripts/setup.sh ghostnet

# 2. Generate keys
docker exec tezos-node tezos-client gen keys alice

# 3. Fund from faucet
# Visit: https://faucet.ghostnet.teztnets.xyz/
# Get your address with: docker exec tezos-node tezos-client show address alice

# 4. Start baking
./scripts/start.sh alice ghostnet

# 5. Check status
./scripts/status.sh

OPTIONAL: Cleanup duplicates
./scripts/cleanup-duplicates.sh

TROUBLESHOOTING:
- Node won't sync: Check docker logs tezos-node
- Baker won't start: Ensure node synced first
- No baking rights: Wait 5-7 cycles (14-21 days on testnet)

For detailed instructions, see: docs/AI_COMPLETE_PROMPT.md
```

---

## 🎯 What the AI Should Do

### Minimal Path (Option 1) - 10 minutes
1. Run `./scripts/setup.sh ghostnet`
2. Generate keys
3. Fund from faucet
4. Start baker with `./scripts/start.sh alice ghostnet`
5. Monitor with `./scripts/status.sh`

### Clean Path (Option 2) - 30 minutes
1. Run `./scripts/cleanup-duplicates.sh` (removes 54MB bloat)
2. Follow minimal path above

---

## 💡 Tips for Different AI Platforms

### ChatGPT (OpenAI)
```
Limitations: Cannot execute commands directly
Best approach: Have AI provide commands, you execute them

Paste: Full docs/AI_COMPLETE_PROMPT.md
Ask: "Guide me through Option 1, giving me commands to run"
```

### Claude (Anthropic)
```
Limitations: Cannot access your filesystem
Best approach: AI provides detailed step-by-step guide

Paste: Full docs/AI_COMPLETE_PROMPT.md
Ask: "I'll run commands you suggest and report results"
```

### Cursor/Aider (Local AI)
```
Capabilities: Can read files and execute commands
Best approach: Direct execution

Command: "Read docs/AI_COMPLETE_PROMPT.md and execute Option 1"
```

### GitHub Copilot
```
Limitations: Code completion focused
Best approach: Use for understanding, not execution

Use: Ask to explain specific scripts or configurations
```

---

## 📊 File Sizes Reference

**What to Copy:**
- `docs/AI_COMPLETE_PROMPT.md` - **22KB** (complete guide)
- `docs/SIMPLIFICATION_ANALYSIS.md` - **6KB** (quick summary)
- `README.md` - **2KB** (quick start)

**Token Estimates:**
- AI_COMPLETE_PROMPT.md: ~6,000 tokens
- SIMPLIFICATION_ANALYSIS.md: ~1,500 tokens
- README.md: ~500 tokens

Most AI models can handle 6,000 tokens easily.

---

## 🔧 What If AI Gets Confused?

### Problem: AI doesn't understand structure
**Solution:** Point to specific file
```
The scripts are in scripts/ folder, not root.
Run: ./scripts/setup.sh (not ./setup.sh)
```

### Problem: AI suggests wrong paths
**Solution:** Remind about organization
```
Remember:
- Scripts: ./scripts/*.sh
- Docs: ./docs/*.md
- Configs: ./*.json at root
```

### Problem: AI wants to delete scripts/ folder
**Solution:** Stop immediately
```
STOP! Do NOT delete scripts/ folder.
Only delete: config/, docker/, agents/
Use: ./scripts/cleanup-duplicates.sh (safe cleanup)
```

---

## ✅ Checklist for Handing Off to AI

Before giving to another AI:

- [ ] Copy `docs/AI_COMPLETE_PROMPT.md` completely
- [ ] Specify which option you want (Option 1 or Option 2)
- [ ] Clarify AI's capabilities (can it execute commands?)
- [ ] Be ready to run commands AI suggests
- [ ] Have terminal access ready
- [ ] Know your repository path: `/Users/admin/tezos-baker`

---

## 🎓 Example Conversation with AI

**You:**
```
I need help setting up a Tezos baker on Ghostnet testnet.

I have a repository at /Users/admin/tezos-baker

Here's the complete setup prompt:
[paste docs/AI_COMPLETE_PROMPT.md contents]

I want Option 1 (just run testnet, skip cleanup).

Please guide me step by step. I'll execute commands and report results.
```

**AI Will:**
1. Confirm it understands the structure
2. Ask you to run `./scripts/setup.sh ghostnet`
3. Wait for your output
4. Guide you through next steps
5. Help troubleshoot any issues

**You:**
Report outputs like:
```
Ran: ./scripts/setup.sh ghostnet
Output: [paste actual output]
```

---

## 📞 Quick Reference

| File | Purpose | Size |
|------|---------|------|
| `docs/AI_COMPLETE_PROMPT.md` | Complete guide for AI | 22KB |
| `docs/SIMPLIFICATION_ANALYSIS.md` | Quick summary | 6KB |
| `README.md` | Human quick start | 2KB |
| `docs/STRUCTURE.md` | Repository organization | 4KB |

**Repository Location:** `/Users/admin/tezos-baker`

**Key Commands:**
- Setup: `./scripts/setup.sh ghostnet`
- Start: `./scripts/start.sh alice ghostnet`
- Status: `./scripts/status.sh`
- Cleanup: `./scripts/cleanup-duplicates.sh`

---

## 🚨 Important Warnings

**Tell the AI:**

⚠️ **Scripts are in scripts/ folder, NOT at root**
- Use: `./scripts/setup.sh`
- NOT: `./setup.sh`

⚠️ **Do NOT delete scripts/ or docs/ folders**
- Only delete: `config/`, `docker/`, `agents/`
- Use safe script: `./scripts/cleanup-duplicates.sh`

⚠️ **This is TESTNET - tokens have no value**
- Safe to experiment
- Can restart anytime
- No real money at risk

---

## ✨ Success Criteria

The AI setup is successful when:

✅ Node is syncing (`./scripts/status.sh` shows sync progress)
✅ Keys generated (can see address with `docker exec tezos-node tezos-client show address alice`)
✅ Account funded from faucet
✅ Baker and endorser running (`docker logs tezos-baker` shows activity)

**Timeline:**
- Setup: 10 minutes
- Sync: 1-3 hours
- First baking rights: 14-21 days (testnet)

---

**Need More Help?**
- See: `docs/AI_COMPLETE_PROMPT.md` (complete guide)
- See: `docs/ARCHITECTURE.md` (technical details)
- See: `docs/INDEX.md` (documentation catalog)
