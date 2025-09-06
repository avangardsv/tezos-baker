# AI Activity Log

This repository keeps a lightweight, append-only audit log of AI (and human) actions.

## Files
- `.ai/log.jsonl`: JSON Lines file with one entry per step.
- `scripts/ai_log.sh`: helper that appends structured entries. Reads details from stdin.

## Usage
Append a log entry (details from stdin):

```
echo "Updated operator docs" | scripts/ai_log.sh docs update \
  --files docs/tezos-baker/README.md \
  --meta plan_step=M1 --meta head_lag_check=true
```

Tail the log:

```
tail -f .ai/log.jsonl
```

Parse last 5 entries (jq):

```
jq -sr '.[-5:]' .ai/log.jsonl
```

## Environment Variables
- `AI_ACTOR`: actor name to record (default: `codex-cli`).
- `AI_SESSION`: session/run identifier (optional).
- `AI_PLAN_STEP`: current plan step label (optional).

## Optional: Require log updates in commits
Enable hooks:

```
git config core.hooksPath .githooks
```

The provided hook blocks commits that modify files without updating `.ai/log.jsonl`.
