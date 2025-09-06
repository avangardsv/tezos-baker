# Repository Guidelines

## Most Important Rule — AI Activity Logging
- Claude and Codex MUST log every step to `.ai/log.jsonl` using `scripts/ai_log.sh`, and produce a daily summary at `logs/ai/YYYY-MM-DD.md`.
- Example: `echo "Updated compose for Ghostnet" | scripts/ai_log.sh ops update --files docker/compose.ghostnet.yml`


## Project Structure & Module Organization
- `docker/`: Compose files (`compose.ghostnet.yml`, `compose.mainnet.yml`), `octez.Dockerfile`, healthchecks, entrypoints.
- `scripts/`: Operational helpers (e.g., `import_snapshot.sh`, `check_sync.sh`, `register_delegate.sh`, `backup_keys.sh`).
- `config/`: Network configs (`ghostnet-config.json`, `mainnet-config.json`). No secrets.
- `monitoring/`: Prometheus, Grafana dashboards, Alertmanager routes.
- `security/`: Hardening guides (UFW, remote signer, baseline checklists).
- `docs/tezos-baker/`: Operator guide, runbooks, security/monitoring details.
- `ci/`: Sanity checks. `logs/`: transient logs; safe to prune.
- Root: `.env.example` with required variables.

## Build, Test, and Development Commands
- Up (Ghostnet): `docker compose -f docker/compose.ghostnet.yml up -d`
- Down: `docker compose -f docker/compose.ghostnet.yml down`
- Validate compose: `docker compose -f docker/compose.ghostnet.yml config`
- Check sync: `scripts/check_sync.sh` (expect head lag <2)
- Import snapshot: `scripts/import_snapshot.sh ghostnet`
- Register delegate: `scripts/register_delegate.sh my_baker`
- Backup keys: `scripts/backup_keys.sh`

## Coding Style & Naming Conventions
- Shell: bash with `set -euo pipefail`; functions + clear usage. Filenames: kebab-case verbs (e.g., `start_baker.sh`).
- YAML: 2-space indent; quote env interpolation; add `healthcheck` for long-lived services.
- JSON: compact and valid; verify with `jq -e . <file>`.

## Testing Guidelines
- Always validate on Ghostnet first. Prove: `tezos-client bootstrapped --block 2` and <2 block lag for 60m.
- Dry-run compose (`docker compose ... config`); capture sample logs.
- Optional helpers: `scripts/test_logging.sh`, `scripts/validate_logs.sh`.
- Place synthetic monitoring rules under `monitoring/prometheus/rules/` and document thresholds.

## Commit & Pull Request Guidelines
- Commits: Conventional Commits (e.g., `feat(ghostnet): add compose file`).
- PRs must include: description, linked issues, command transcript (key scripts), and screenshots (Grafana, alerts).
- Security: never commit secrets; use `.env` locally only; prefer secrets managers in prod.
- Scope small; update docs/runbooks when behavior changes.

## AI Activity Logging (Daily)
- Append each AI/operator step to `.ai/log.jsonl` using `scripts/ai_log.sh`.
- Create a short daily summary in `logs/ai/$(date +%F).md` listing key actions and outcomes.
- Example rollup: `jq -r 'select(.ts|startswith("'"$(date +%F)"'")) | "- [\(.ts)] \(.category)/\(.action) (\(.files|join(", ")))"' .ai/log.jsonl > logs/ai/$(date +%F).md`
- PRs should reference the latest daily summary when changes were AI-assisted.
