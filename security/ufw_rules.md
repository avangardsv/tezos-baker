# UFW Firewall Configuration for Tezos Baker

## Basic UFW Setup

### Initial Configuration
```bash
# Reset UFW to defaults
sudo ufw --force reset

# Set default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Enable UFW logging
sudo ufw logging on
```

## Required Rules for Tezos Baker

### Essential Ports
```bash
# SSH access (change port if using non-standard)
sudo ufw allow ssh
# Or for custom SSH port:
# sudo ufw allow 2222/tcp

# Tezos P2P port (required for node communication)
sudo ufw allow 9732/tcp
sudo ufw comment on 9732 "Tezos P2P"
```

### Conditional Rules

#### RPC Access (Use with Caution)
```bash
# Only allow RPC from localhost (recommended)
# No firewall rule needed as it's bound to 127.0.0.1

# Allow RPC from specific IP (if absolutely necessary)
sudo ufw allow from 192.168.1.100 to any port 8732
sudo ufw comment on 8732 "Tezos RPC - Specific IP"

# Allow RPC from local network (NOT recommended for mainnet)
sudo ufw allow from 192.168.1.0/24 to any port 8732
sudo ufw comment on 8732 "Tezos RPC - Local Network"
```

#### Monitoring Access
```bash
# Prometheus (if accessing from monitoring server)
sudo ufw allow from 192.168.1.200 to any port 9090
sudo ufw comment on 9090 "Prometheus - Monitoring Server"

# Grafana (if accessing externally)
sudo ufw allow from 192.168.1.0/24 to any port 3000
sudo ufw comment on 3000 "Grafana - Local Network"

# Node exporter (if accessing from monitoring server)
sudo ufw allow from 192.168.1.200 to any port 9100
sudo ufw comment on 9100 "Node Exporter - Monitoring Server"
```

#### Remote Signer (If Used)
```bash
# Remote signer port (only from baker nodes)
sudo ufw allow from 192.168.1.50 to any port 6732
sudo ufw comment on 6732 "Tezos Remote Signer"
```

## Network-Specific Configurations

### Ghostnet (Testing)
```bash
# More permissive for testing
sudo ufw allow 8732/tcp comment "Ghostnet RPC - Testing Only"
sudo ufw allow 9095/tcp comment "Ghostnet Metrics - Testing Only"
```

### Mainnet (Production)
```bash
# Very restrictive - only essential ports
# P2P port is the only publicly accessible port
sudo ufw allow 9732/tcp comment "Mainnet P2P"

# All other services bound to localhost
# No additional firewall rules needed for RPC/monitoring
```

## Advanced Rules

### Rate Limiting
```bash
# Limit SSH connection attempts
sudo ufw limit ssh comment "SSH Rate Limiting"

# Limit connections to P2P port (if experiencing attacks)
sudo ufw limit 9732/tcp comment "P2P Rate Limiting"
```

### Geo-blocking (Using IP Lists)
```bash
# Block known malicious IP ranges (example)
sudo ufw deny from 1.2.3.0/24 comment "Blocked malicious range"

# Allow only specific countries (requires external IP lists)
# This is complex and requires additional tools
```

### Application-Specific Rules
```bash
# Docker daemon (if exposing Docker API)
sudo ufw allow from 192.168.1.0/24 to any port 2376
sudo ufw comment on 2376 "Docker API - Local Network"

# SNMP monitoring (if used)
sudo ufw allow from 192.168.1.200 to any port 161
sudo ufw comment on 161 "SNMP - Monitoring Server"
```

## Enable Firewall
```bash
# Enable UFW (will apply all rules)
sudo ufw enable

# Check status
sudo ufw status verbose
sudo ufw status numbered
```

## Maintenance Commands

### Viewing Rules
```bash
# Show all rules with numbers
sudo ufw status numbered

# Show listening ports
sudo netstat -tuln

# Show active connections
sudo ss -tuln
```

### Modifying Rules
```bash
# Delete rule by number
sudo ufw delete 3

# Delete rule by specification
sudo ufw delete allow 8732/tcp

# Insert rule at specific position
sudo ufw insert 1 allow from 192.168.1.100 to any port 22
```

### Logging
```bash
# Enable detailed logging
sudo ufw logging full

# View UFW logs
sudo tail -f /var/log/ufw.log

# View denied connections
sudo grep "UFW BLOCK" /var/log/ufw.log
```

## Security Best Practices

### 1. Principle of Least Privilege
- Only open ports that are absolutely necessary
- Use source IP restrictions whenever possible
- Regularly review and remove unused rules

### 2. Default Deny
- Always use "default deny incoming"
- Be explicit about what you allow
- Document the purpose of each rule

### 3. Regular Auditing
```bash
# Monthly firewall audit script
#!/bin/bash
echo "=== UFW Status ==="
sudo ufw status verbose

echo -e "\n=== Listening Ports ==="
sudo netstat -tuln

echo -e "\n=== Recent Denied Connections ==="
sudo grep "UFW BLOCK" /var/log/ufw.log | tail -20
```

### 4. Testing Rules
```bash
# Test connectivity from external host
nmap -p 9732 your-baker-ip

# Test RPC access (should timeout if properly restricted)
curl -m 5 http://your-baker-ip:8732/chains/main/blocks/head
```

## Example Complete Configuration

### Minimal Production Setup
```bash
#!/bin/bash
# Tezos Baker UFW Configuration - Production

# Reset and set defaults
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw logging on

# Essential access
sudo ufw allow ssh comment "SSH Access"
sudo ufw allow 9732/tcp comment "Tezos P2P"

# Rate limiting for SSH
sudo ufw limit ssh

# Enable firewall
sudo ufw enable

echo "Firewall configured for production Tezos baker"
sudo ufw status verbose
```

### Development/Testing Setup
```bash
#!/bin/bash
# Tezos Baker UFW Configuration - Development

# Reset and set defaults
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw logging on

# Essential access
sudo ufw allow ssh comment "SSH Access"
sudo ufw allow 9732/tcp comment "Tezos P2P"

# Development access (use with caution)
sudo ufw allow from 192.168.1.0/24 to any port 8732 comment "RPC - Local Network"
sudo ufw allow from 192.168.1.0/24 to any port 3000 comment "Grafana - Local Network"
sudo ufw allow from 192.168.1.0/24 to any port 9090 comment "Prometheus - Local Network"

# Enable firewall
sudo ufw enable

echo "Firewall configured for development/testing"
sudo ufw status verbose
```

## Troubleshooting

### Common Issues

#### Can't Connect to RPC
```bash
# Check if RPC is bound to correct interface
sudo netstat -tuln | grep 8732

# Check UFW logs for blocked connections
sudo grep "8732" /var/log/ufw.log
```

#### P2P Connection Issues
```bash
# Check P2P port accessibility
nmap -p 9732 localhost

# Check for blocked P2P connections
sudo grep "9732" /var/log/ufw.log
```

#### Too Many Denied Connections
```bash
# Find most common blocked IPs
sudo grep "UFW BLOCK" /var/log/ufw.log | awk '{print $13}' | sort | uniq -c | sort -nr | head -10

# Consider adding permanent blocks for persistent attackers
sudo ufw deny from suspicious.ip.address
```

### Emergency Access Recovery
If you're locked out due to firewall rules:

1. **Physical/Console Access**: Use server console to modify rules
2. **Cloud Provider Console**: Use web-based console access
3. **Rescue Mode**: Boot from rescue disk to modify configuration
4. **Reset Script**: Have a scheduled script that resets UFW periodically

---

**⚠️ Warning**: Always test firewall rules carefully, especially on remote systems. Incorrect rules can lock you out of your server.