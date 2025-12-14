# Upgrades, Protocol Changes, and Patching

## General Principles
- Treat Tezos protocol changes as planned change windows; avoid emergency upgrades.
- Mirror environments: test on Ghostnet first, then promote to Mainnet with identical config.
- Keep Octez binaries and Docker images pinned by digest to avoid drift.

## Pre-Upgrade Checklist
- Review protocol proposal timeline and required Octez versions from https://tezos.gitlab.io/.
- Ensure backups: latest node snapshot and signer config exported and validated.
- Verify monitoring coverage for new metrics; update dashboards/importers if endpoints change.
- Announce maintenance window and expected downtime (if any).

## Ghostnet Dry-Run
- Apply new Octez release on Ghostnet within 72h of publication.
- Run through: snapshot import (if needed), node bootstrap, baker/endorser start, rights observed for at least one cycle, alerts quiet.
- Record findings, config changes, and any manual steps.

## Mainnet Rollout
- Schedule upgrade at least one week before protocol activation with rollback plan (previous image + snapshot).
- Upgrade sequence:
  1. Stop baker/endorser; drain mempool if needed.
  2. Upgrade node image/binary; restart and confirm bootstrap.
  3. Upgrade remote signer if required; validate with dry-run signing on Ghostnet keys.
  4. Restart baker/endorser and monitor rights execution for 1–2 cycles.
- If head lag persists >20 blocks or errors appear, roll back to last known good version and investigate offline.

## Patching & Maintenance
- Apply security patches to host OS weekly via unattended upgrades; reboot window monthly.
- Refresh Docker base images monthly; rebuild and push pinned digests.
- Track dependencies (scripts/infra) with `CHANGELOG` entries and keep compatibility with current protocol.

## Validation Artifacts
- Keep a short report for each upgrade: date, version, environment, duration, validation steps, and screenshots/metrics links.
- Store reports alongside runbooks for auditability and team knowledge sharing.
