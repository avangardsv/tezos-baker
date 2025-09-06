# Security & Key Management

## Principles
- Least privilege, immutable infra where possible, auditability over convenience.
- Separate data, keys, and monitoring volumes; restrict mounts to minimum.

## Keys
- Ghostnet: software keys acceptable (test only) stored under `/var/lib/tezos-keys` with 600 perms.
- Mainnet: hardware wallet (Ledger) + remote signer. Do not import mnemonics or private keys to servers.

## Backups
- Keys: encrypted tar (age or GPG) of key volume; store offsite (e.g., S3 with object lock).
- Test restore quarterly using `restore_keys.sh` against a disposable node.

## Network & OS
- UFW allowlist: p2p `9732/tcp`, RPC restricted to admin subnet, monitoring behind auth.
- SSH keys only; disable password auth; fail2ban; unattended upgrades.

## Containers
- Run as non-root; read-only FS where viable; drop capabilities; healthchecks on all services.
- Never mount the Docker socket; avoid broad binds.

## Secrets Handling
- Use `.env` for local dev only; production via secret manager or Docker secrets.
- Rotate credentials; log and alert on failed signer calls.
