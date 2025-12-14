# Security & Key Management

## Principles
- Least privilege, immutable infra where possible, auditability over convenience.
- Separate data, keys, and monitoring volumes; restrict mounts to minimum.
- Prefer hardware-backed keys and remote signing; servers should not hold private keys.

## Keys
- **Ghostnet:** software keys acceptable (test only) stored under `/var/lib/tezos-keys` with 600 perms.
- **Mainnet:** hardware wallet (Ledger) + remote signer. Do not import mnemonics or private keys to servers.
- **Authorization:** Limit signer ACLs to the baker address; rotate tokens on role changes.

## Key Management Approach
- **Remote signer host:** Hardened VM or physical host with minimal services, dedicated to Ledger. Enable UFW to allow only RPC (6732) from node IPs; SSH via jump host with 2FA.
- **Backup:**
  - Ledger recovery phrases sealed in two locations with access log; do not digitize.
  - Weekly encrypted backup of signer config/ACLs to offsite storage (object lock). Verify GPG/age recipients quarterly.
  - Retain the latest 4 weekly backups and 3 quarterly images.
- **Restore:**
  - Test on Ghostnet quarterly: rebuild signer from backup, pair with spare Ledger, confirm signing a right, then revoke test signer.
  - Document results in the ops log and track follow-up fixes.

## Backups
- Keys: encrypted tar (age or GPG) of key volume; store offsite (e.g., S3 with object lock).
- Test restore quarterly using `restore_keys.sh` against a disposable node.

## Network & OS
- UFW allowlist: p2p `9732/tcp`, RPC restricted to admin subnet, monitoring behind auth.
- SSH keys only; disable password auth; fail2ban; unattended upgrades.
- Keep NTP enabled; clock drift can invalidate rights and harm consensus.

## Containers
- Run as non-root; read-only FS where viable; drop capabilities; healthchecks on all services.
- Never mount the Docker socket; avoid broad binds.

## Secrets Handling
- Use `.env` for local dev only; production via secret manager or Docker secrets.
- Rotate credentials; log and alert on failed signer calls.
- Avoid embedding secrets in images or git history; scrub using pre-commit hooks.
