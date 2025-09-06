# Tezos Baker Logs

This directory contains workflow and script execution logs with structured format.

## Log File Naming Convention

```
logs/<workflow-name>_<YYYY-MM-DD>.log
```

Examples:
- `logs/import_snapshot_2025-09-06.log`
- `logs/start_baker_2025-09-06.log` 
- `logs/register_delegate_2025-09-06.log`

## Log Entry Format

Each log entry follows this structure:
```
[TIMESTAMP] [STEP_NAME] [STATUS] - MESSAGE
```

### Status Values
- `START` - Step beginning
- `SUCCESS` - Step completed successfully  
- `ERROR` - Step failed
- `WARNING` - Non-critical issue
- `INFO` - Informational message

### Example Log Entries
```
[2025-09-06 14:10:02] SNAPSHOT_IMPORT START - Downloading ghostnet snapshot
[2025-09-06 14:10:05] SNAPSHOT_IMPORT SUCCESS - Downloaded ghostnet.full (500MB)
[2025-09-06 14:12:32] SNAPSHOT_IMPORT START - Importing snapshot into node
[2025-09-06 14:15:02] SNAPSHOT_IMPORT SUCCESS - Imported snapshot in 2m30s
[2025-09-06 14:15:01] NODE_START START - Starting Tezos node
[2025-09-06 14:15:03] NODE_START SUCCESS - Node started with PID=12345
[2025-09-06 14:16:20] REGISTER_DELEGATE ERROR - Insufficient funds for registration
```

## Log Rotation

- Logs are organized by date (one file per script per day)
- Old logs should be archived/compressed monthly
- Consider setting up log rotation via `logrotate` for production

## Monitoring Integration

Logs can be ingested by:
- Promtail → Loki → Grafana
- Elasticsearch + Kibana  
- Cloud logging services (AWS CloudWatch, GCP Cloud Logging)
- Simple `tail -f logs/*.log | grep ERROR` for monitoring

## Parsing Logs

The structured format allows easy parsing:

```bash
# Count errors per day
grep "ERROR" logs/import_snapshot_*.log | wc -l

# Extract all SUCCESS messages
awk '/SUCCESS/' logs/*.log

# Monitor specific step
grep "SNAPSHOT_IMPORT" logs/import_snapshot_2025-09-06.log

# Real-time monitoring
tail -f logs/*.log | grep -E "(ERROR|WARNING)"
```