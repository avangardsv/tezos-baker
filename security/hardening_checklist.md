# Tezos Baker Security Hardening Checklist

## System Hardening

### ✅ Operating System
- [ ] **Keep OS updated**: `sudo apt update && sudo apt upgrade -y`
- [ ] **Disable unused services**: Review and disable unnecessary system services
- [ ] **Configure automatic security updates**: Set up unattended-upgrades
- [ ] **Set strong root password**: Use complex password or disable root login
- [ ] **Configure proper hostname**: Set meaningful hostname for identification

### ✅ User Management
- [ ] **Create dedicated user**: Run Tezos services as non-root user
- [ ] **Configure SSH keys**: Use key-based authentication instead of passwords
- [ ] **Disable password authentication**: Edit `/etc/ssh/sshd_config`
- [ ] **Use sudo for admin tasks**: Add user to sudo group, avoid direct root access
- [ ] **Set proper file permissions**: Ensure sensitive files have restrictive permissions

### ✅ Network Security
- [ ] **Configure UFW firewall**: Enable and configure uncomplicated firewall
  ```bash
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw allow ssh
  sudo ufw allow 9732/tcp  # Tezos P2P
  sudo ufw allow 8732/tcp  # RPC (if needed externally)
  sudo ufw enable
  ```
- [ ] **Close unnecessary ports**: Only expose required ports (9732 for P2P)
- [ ] **Use fail2ban**: Install and configure to prevent brute force attacks
- [ ] **Monitor network connections**: Regularly check active connections
- [ ] **Use VPN for remote access**: Avoid exposing SSH to internet

### ✅ Docker Security
- [ ] **Use non-root containers**: Configure user namespaces
- [ ] **Limit container resources**: Set memory and CPU limits
- [ ] **Use official images**: Only use trusted base images
- [ ] **Regular image updates**: Keep container images updated
- [ ] **Scan for vulnerabilities**: Use tools like `docker scan`

## Tezos-Specific Security

### ✅ Key Management
- [ ] **Use hardware wallet**: Ledger Nano S/X for mainnet operations
- [ ] **Backup keys securely**: Encrypted backups in multiple locations
- [ ] **Test key recovery**: Verify backup restoration process
- [ ] **Use remote signer**: Separate key management from node operations
- [ ] **Monitor key access**: Log and monitor key usage

### ✅ Node Configuration
- [ ] **Restrict RPC access**: Bind RPC to localhost only in production
  ```json
  "rpc": {
    "listen-addrs": ["127.0.0.1:8732"]
  }
  ```
- [ ] **Disable CORS for production**: Remove CORS headers for external access
- [ ] **Use strong peer filtering**: Configure trusted bootstrap peers only
- [ ] **Enable connection limits**: Set maximum peer connections
- [ ] **Configure log rotation**: Prevent log files from filling disk

### ✅ Baker Security
- [ ] **Validate delegate balance**: Ensure minimum 6000 XTZ for mainnet
- [ ] **Monitor baking activity**: Set up alerts for missed slots
- [ ] **Use separate accounts**: Different keys for different purposes
- [ ] **Test on testnet first**: Validate setup on Ghostnet
- [ ] **Implement double-baking protection**: Use slashing protection mechanisms

## Monitoring & Alerting

### ✅ System Monitoring
- [ ] **Set up Prometheus**: Collect system and application metrics
- [ ] **Configure Grafana**: Create dashboards for visualization
- [ ] **Enable log aggregation**: Centralize logs from all services
- [ ] **Monitor disk usage**: Alert on high disk utilization
- [ ] **Track network activity**: Monitor for unusual traffic patterns

### ✅ Security Monitoring
- [ ] **Monitor failed login attempts**: Track SSH authentication failures
- [ ] **Set up file integrity monitoring**: Use tools like AIDE or Tripwire
- [ ] **Monitor process activity**: Track running processes and changes
- [ ] **Log access to sensitive files**: Monitor key file access
- [ ] **Set up intrusion detection**: Use tools like OSSEC or Suricata

### ✅ Alerting Configuration
- [ ] **Critical alerts**: Node down, baker/endorser offline
- [ ] **Warning alerts**: High resource usage, peer connectivity issues
- [ ] **Security alerts**: Failed authentications, file changes
- [ ] **Multiple channels**: Email, Slack, SMS for critical alerts
- [ ] **Test alert delivery**: Verify all alert channels work

## Backup & Recovery

### ✅ Data Backup
- [ ] **Backup Tezos keys**: Encrypted backups of wallet keys
- [ ] **Backup node identity**: Save node identity for faster recovery
- [ ] **Backup configuration**: Save all configuration files
- [ ] **Regular backup testing**: Verify backup integrity monthly
- [ ] **Offsite storage**: Store backups in different physical locations

### ✅ Recovery Planning
- [ ] **Document recovery procedures**: Step-by-step recovery guide
- [ ] **Test recovery process**: Practice full system recovery
- [ ] **Prepare recovery environment**: Have spare hardware/cloud resources
- [ ] **Recovery time objectives**: Define acceptable downtime limits
- [ ] **Emergency contacts**: List of key personnel and vendors

## Operational Security

### ✅ Access Control
- [ ] **Multi-factor authentication**: Enable MFA where possible
- [ ] **Principle of least privilege**: Grant minimum necessary permissions
- [ ] **Regular access reviews**: Audit user permissions quarterly
- [ ] **Secure communication**: Use encrypted channels for coordination
- [ ] **Documentation access**: Secure storage for operational documents

### ✅ Change Management
- [ ] **Testing procedures**: Test all changes on testnet first
- [ ] **Rollback procedures**: Document how to revert changes
- [ ] **Change approval**: Require approval for critical changes
- [ ] **Maintenance windows**: Schedule changes during low activity
- [ ] **Change documentation**: Record all configuration changes

### ✅ Incident Response
- [ ] **Incident response plan**: Document response procedures
- [ ] **Contact information**: Emergency contact list
- [ ] **Isolation procedures**: Steps to isolate compromised systems
- [ ] **Evidence preservation**: Procedures for forensic analysis
- [ ] **Post-incident review**: Process for learning from incidents

## Regular Security Tasks

### Daily
- [ ] Check system alerts and logs
- [ ] Monitor baker/endorser status
- [ ] Verify node synchronization
- [ ] Check system resource usage

### Weekly  
- [ ] Review security logs
- [ ] Check backup completion
- [ ] Monitor peer connections
- [ ] Update security configurations if needed

### Monthly
- [ ] Security patch updates
- [ ] Access permission review
- [ ] Backup integrity testing
- [ ] Security metric analysis

### Quarterly
- [ ] Full security assessment
- [ ] Disaster recovery testing
- [ ] Security policy review
- [ ] Penetration testing (if applicable)

## Emergency Procedures

### Node Compromise Response
1. **Immediate isolation**: Disconnect from network
2. **Stop baking operations**: Prevent further transactions
3. **Assess damage**: Determine scope of compromise
4. **Notify stakeholders**: Inform relevant parties
5. **Forensic analysis**: Preserve evidence for investigation
6. **Recovery planning**: Plan restoration approach

### Key Compromise Response
1. **Immediate delegation**: Transfer delegation if possible
2. **Key rotation**: Generate new keys immediately
3. **Monitor transactions**: Watch for unauthorized operations
4. **Notify network**: Inform other bakers if relevant
5. **Update security**: Strengthen key management practices

---

## Verification Commands

```bash
# Check firewall status
sudo ufw status verbose

# Check for root login attempts
sudo grep "Failed password for root" /var/log/auth.log

# Check running services
systemctl list-units --type=service --state=running

# Check file permissions on key files
ls -la ~/.tezos-client/

# Check Docker container security
docker container ls --format "table {{.Names}}\t{{.RunningFor}}\t{{.Status}}"

# Monitor system resources
htop

# Check network connections
ss -tuln
```

**Security is an ongoing process. Review and update this checklist regularly based on new threats and best practices.**