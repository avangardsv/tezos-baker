# Contributing — Tezos Baker

## Workflow
- Branches: `feat/*`, `fix/*`, `docs/*`, `ops/*` (scripts/infra changes).
- Commits: Conventional Commits (e.g., `feat(ghostnet): add compose file`).
- PRs: small, focused; include description, linked issues, test evidence (logs, screenshots), and rollback notes.

## Directory Ownership
- `docker/`: compose files, Dockerfiles.
- `scripts/`: shell scripts; must be idempotent and re-runnable.
- `config/`: network-specific config; no secrets.
- `monitoring/`: Prometheus, Alertmanager, Grafana dashboards.
- `runbooks/`: step-by-step ops instructions.
- `security/`: guides, checklists; never store credentials.

## Shell & YAML Style
- Shell: `set -euo pipefail`; prefer `bash` with strict mode; validate inputs.
- Naming: kebab-case for files; verbs for scripts (e.g., `check_sync.sh`).
- YAML: 2-space indent; quote interpolated envs; add `healthcheck` for long-lived services.

## Reviews & Testing
- Ghostnet first: verify `tezos-client bootstrapped` and head lag <2.
- Provide `docker compose config` output for validation.
- Include command transcript for risky operations (e.g., snapshot import, key ops).

## CI Expectations (sanity)
- Lint shell (`shellcheck`), YAML (`yamllint`), and JSON (`jq -e .`).
- Dry-run compose files; basic script smoke tests.

## Security Footing for PRs
- No secrets in code or history. Use `.env` and secret managers.
- Key operations require reviewer ACK and clear rollback.
