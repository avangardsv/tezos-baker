# Tezos Baker Security Guide

## Overview

Security is **critical for production bakers** handling real funds. This guide covers comprehensive security best practices for testnet and mainnet deployments.

## Current Status (Testnet)

Your current configuration:
```json
{
  "rpc": {
    "listen-addrs": ["0.0.0.0:8732"],
    "acl": [{"address": "0.0.0.0", "blacklist": []}]
  }
}
```

**Status: ⚠️ Open to all (Acceptable for testnet only)**

## Why RPC Security Matters

**RPC (Remote Procedure Call)** is the HTTP API endpoint (port 8732) that allows:
- Querying blockchain data
- Submitting transactions
- Calling smart contracts
- Node operations

### Attack Risks

**Without proper ACL (Access Control List):**

| Risk | Impact | Severity |
|------|--------|----------|
| **DoS Attacks** | Spam RPC → Node unresponsive → Miss baking slots → Lost rewards | 🔴 Critical |
| **Information Leakage** | Attackers discover network topology, peer connections | 🟡 Medium |
| **Resource Exhaustion** | Heavy queries consume CPU/memory → Node crashes | 🔴 Critical |
| **Transaction Injection** | Mempool pollution, delayed legitimate transactions | 🟡 Medium |
| **Network Abuse** | Your node used to attack others (DDoS amplification) | 🟠 High |

### Real-World Attack Scenario

**Mainnet Baker with Open RPC:**

1. **Discovery Phase**
   - Attacker scans internet for open port 8732
   - Finds your node: `curl http://your-ip:8732/chains/main/chain_id`
   - Confirms it's a baker

2. **Resource Attack**
   - Floods RPC with expensive queries
   - Node CPU spikes to 100%
   - Node misses baking slot (expected in 30 seconds)

3. **Financial Impact**
   - **Missed baking reward:** ~0.5 XTZ per block
   - **Missed endorsing rewards:** ~0.1 XTZ × endorsements
   - **Total loss per missed slot:** ~$1-2 USD
   - **If sustained:** Loss of baker reputation, delegators leave

4. **Worse Case**
   - If baker keys are accessible via node
   - Attacker could steal delegation or funds
   - **Mainnet loss:** Potentially thousands of dollars

---

## Configure RPC ACL

### Interactive Configuration

```bash
npm run security:configure-acl
```

This interactive script helps you choose:
1. **Localhost only** (most secure)
2. **Whitelist specific IPs** (secure remote access)
3. **Private network** (VPN/cloud)
4. **Open to all** (testnet only)
5. **Show examples** and exit

### Manual Configuration Options

#### Option 1: Localhost Only (Recommended for Solo Bakers)

```json
{
  "rpc": {
    "listen-addrs": ["127.0.0.1:8732"]
  }
}
```

**Benefits:**
- ✅ Most secure (only local access)
- ✅ No external exposure
- ✅ Perfect for single-server setups

**Use case:** Solo baker on single machine

**Commands work:** `docker exec`, local `curl`  
**Remote access:** No

#### Option 2: Whitelist Specific IPs (For Remote Monitoring)

```json
{
  "rpc": {
    "listen-addrs": ["0.0.0.0:8732"],
    "acl": [
      {
        "address": "192.168.1.100",
        "blacklist": []
      },
      {
        "address": "203.0.113.50",
        "blacklist": []
      }
    ]
  }
}
```

**Benefits:**
- ✅ Secure remote access
- ✅ Multiple authorized IPs
- ✅ Good for monitoring systems

**Use case:** Remote monitoring, multi-server baker setup

**Access:** Only from whitelisted IPs  
**Remote access:** Yes (from whitelisted IPs only)

#### Option 3: Private Network (For VPN/Cloud)

```json
{
  "rpc": {
    "listen-addrs": ["10.0.0.5:8732"],
    "acl": []
  }
}
```

**Benefits:**
- ✅ Network-level isolation
- ✅ No internet exposure
- ✅ Works with VPN

**Use case:** Private cloud, VPN-only access

**Access:** Only from 10.0.0.0/8 private network  
**Remote access:** Yes (if on VPN/private network)

#### Option 4: With Blacklist

```json
{
  "rpc": {
    "listen-addrs": ["0.0.0.0:8732"],
    "acl": [
      {
        "address": "0.0.0.0",
        "blacklist": ["192.0.2.100", "198.51.100.50"]
      }
    ]
  }
}
```

**Use case:** Allow all except specific malicious IPs

### Apply Configuration Changes

After editing `data/config.json`:

```bash
# Restart node to apply changes
npm run node:restart

# Verify new configuration
cat data/config.json | jq '.rpc'

# Test access
curl -s http://127.0.0.1:8732/chains/main/chain_id
```

---

## Defense in Depth

RPC ACL is **one layer**. Production security requires **multiple layers**:

### 1. Firewall (Linux Servers)

#### UFW (Ubuntu/Debian)

```bash
# Default deny all incoming
ufw default deny incoming
ufw default allow outgoing

# Allow SSH (change port if needed)
ufw allow ssh

# Allow P2P (required for blockchain)
ufw allow 9732/tcp

# Allow RPC only from specific IP
ufw allow from 192.168.1.100 to any port 8732

# Deny all other RPC access
ufw deny 8732

# Enable firewall
ufw enable

# Verify
ufw status verbose
```

#### iptables (Alternative)

```bash
# Allow P2P
iptables -A INPUT -p tcp --dport 9732 -j ACCEPT

# Allow RPC from specific IP
iptables -A INPUT -p tcp -s 192.168.1.100 --dport 8732 -j ACCEPT

# Block all other RPC
iptables -A INPUT -p tcp --dport 8732 -j DROP

# Save rules
iptables-save > /etc/iptables/rules.v4

# Verify
iptables -L -n -v
```

### 2. Reverse Proxy with Rate Limiting

**nginx configuration:**

```nginx
# /etc/nginx/sites-available/tezos-rpc

# Rate limiting zone (10MB buffer, 10 requests/second)
limit_req_zone $binary_remote_addr zone=rpc:10m rate=10r/s;

server {
    listen 8732;
    server_name your-baker.example.com;

    # SSL/TLS (recommended)
    # listen 443 ssl;
    # ssl_certificate /path/to/cert.pem;
    # ssl_certificate_key /path/to/key.pem;

    location / {
        # Rate limit (burst allows temporary spikes)
        limit_req zone=rpc burst=20 nodelay;

        # Proxy to node (running on different port)
        proxy_pass http://127.0.0.1:18732;

        # Security headers
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $host;

        # Timeouts (prevent hanging connections)
        proxy_read_timeout 30s;
        proxy_connect_timeout 10s;
        proxy_send_timeout 10s;

        # Buffer settings
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
    }

    # Block common attack paths
    location ~* \.(git|env|sql|bak)$ {
        deny all;
    }
}
```

**Enable and test:**

```bash
# Test configuration
nginx -t

# Reload nginx
systemctl reload nginx

# Verify
curl -I http://localhost:8732/chains/main/chain_id
```

### 3. VPN Access

**WireGuard VPN** (Modern, fast, secure)

```bash
# Install WireGuard
apt install wireguard

# Generate keys
wg genkey | tee privatekey | wg pubkey > publickey

# Configure /etc/wireguard/wg0.conf
[Interface]
PrivateKey = <server_private_key>
Address = 10.0.0.1/24
ListenPort = 51820

[Peer]
PublicKey = <client_public_key>
AllowedIPs = 10.0.0.2/32

# Start VPN
wg-quick up wg0

# Enable on boot
systemctl enable wg-quick@wg0
```

**Configure node for VPN-only access:**

```json
{
  "rpc": {
    "listen-addrs": ["10.0.0.1:8732"]
  }
}
```

**Client access:**

```bash
# Connect to VPN
wg-quick up wg0

# Access RPC through VPN
curl http://10.0.0.1:8732/chains/main/chain_id
```

### 4. SSH Tunnel (Quick Remote Access)

**Simple, no VPN needed:**

```bash
# From your local machine
ssh -L 8732:localhost:8732 user@baker-server

# Keep tunnel open in background
ssh -fNL 8732:localhost:8732 user@baker-server

# Now access RPC locally
curl http://localhost:8732/chains/main/chain_id
```

---

## Production Security Checklist

Before deploying to mainnet:

### 1. RPC & Network Security
- [ ] RPC ACL configured (localhost or whitelist only)
- [ ] Firewall enabled (UFW/iptables)
- [ ] SSH port secured (key-based auth only)
- [ ] P2P port open (9732)
- [ ] RPC port restricted or blocked externally
- [ ] DDoS protection (if using VPS)
- [ ] Rate limiting configured (nginx/cloudflare)
- [ ] No unnecessary ports open

### 2. Key Management
- [ ] Hardware wallet (Ledger) for mainnet
- [ ] Remote signer on isolated machine
- [ ] **Never store mainnet keys on baker node**
- [ ] Baker keys backed up (hardware wallet seed phrase)
- [ ] Seed phrase stored securely (fireproof safe, multiple locations)

### 3. Monitoring & Alerts
- [ ] Node uptime monitoring
- [ ] Block sync monitoring
- [ ] Missed baking/endorsing alerts
- [ ] Disk space alerts (critical for rolling nodes)
- [ ] CPU/memory alerts
- [ ] Peer connection monitoring
- [ ] Log aggregation (optional: ELK, Grafana)

### 4. System Hardening
- [ ] Non-root user for Docker
- [ ] Automatic security updates enabled
- [ ] SSH key-based auth only (no passwords)
- [ ] Fail2ban configured for SSH
- [ ] Minimal software installed
- [ ] SELinux/AppArmor enabled (optional)
- [ ] Regular security audits

### 5. Backup & Recovery
- [ ] Identity file backed up (encrypted)
- [ ] Configuration backed up
- [ ] Disaster recovery plan documented
- [ ] Recovery procedure tested
- [ ] Backup verification (restore test)
- [ ] Off-site backups

### 6. Testing & Validation
- [ ] Testnet baker running for 24-48 hours minimum
- [ ] Verified snapshot import/export
- [ ] Tested node restart recovery
- [ ] Simulated failures (power loss, network outage)
- [ ] Verified baking/endorsing works
- [ ] Checked for missed rights
- [ ] Run `npm run verify` - all green

---

## Security Testing

### Test RPC Exposure

```bash
# Check listening ports
netstat -an | grep 8732
# or
ss -ltn | grep 8732

# Test local access (should work)
curl -s http://127.0.0.1:8732/chains/main/chain_id

# Test external access (should fail if secured)
curl -s http://YOUR_PUBLIC_IP:8732/chains/main/chain_id
```

### Verify Firewall

```bash
# UFW status
sudo ufw status verbose
sudo ufw status numbered

# iptables rules
sudo iptables -L -n -v
sudo iptables -L INPUT -n -v | grep 8732
```

### Port Scan (External Test)

```bash
# From external machine
nmap -p 8732,9732 YOUR_PUBLIC_IP

# Expected result:
# 9732/tcp  open     # P2P (correct)
# 8732/tcp  filtered # RPC (correct - blocked by firewall)
# or
# 8732/tcp  closed   # Also acceptable
```

### Test Rate Limiting

```bash
# Spam RPC endpoint
for i in {1..50}; do
  curl http://localhost:8732/chains/main/chain_id &
done

# Should see 429 (Too Many Requests) if rate limiting works
```

---

## Monitoring Security

### Real-Time Monitoring

```bash
# Watch RPC access (nginx)
tail -f /var/log/nginx/access.log

# Monitor failed SSH attempts
tail -f /var/log/auth.log | grep "Failed"

# Check active RPC connections
netstat -an | grep ESTABLISHED | grep 8732

# Monitor firewall blocks
sudo tail -f /var/log/ufw.log
```

### Automated Alerts

**Example: Simple alert script**

```bash
#!/bin/bash
# /usr/local/bin/baker-monitor.sh

# Check if node is synced
BLOCK_AGE=$(docker exec tezos-node curl -s http://localhost:8732/chains/main/blocks/head/header | jq -r '.timestamp')
NOW=$(date -u +%s)
AGE=$((NOW - $(date -d "$BLOCK_AGE" +%s)))

if [ $AGE -gt 300 ]; then
    echo "WARNING: Node out of sync (${AGE}s behind)" | mail -s "Baker Alert" admin@example.com
fi

# Check disk space
DISK_USAGE=$(df -h /var/lib/docker | awk 'NR==2 {print $5}' | tr -d '%')
if [ $DISK_USAGE -gt 80 ]; then
    echo "WARNING: Disk usage ${DISK_USAGE}%" | mail -s "Baker Alert" admin@example.com
fi
```

**Cron job:**

```bash
# Run every 5 minutes
*/5 * * * * /usr/local/bin/baker-monitor.sh
```

---

## Common Security Mistakes

### ❌ Don't Do This

1. **Store mainnet keys on baker node**
   - Use hardware wallet or remote signer
   
2. **Use open RPC (0.0.0.0) on mainnet**
   - Always use localhost or whitelist
   
3. **Disable firewall "for testing"**
   - Test with firewall enabled
   
4. **Use weak SSH passwords**
   - Use SSH keys only
   
5. **Ignore security updates**
   - Enable automatic updates
   
6. **Run as root user**
   - Create dedicated user
   
7. **Skip backups**
   - Regular backups are critical
   
8. **Expose Docker daemon**
   - Never bind to 0.0.0.0:2375

### ✅ Do This Instead

1. **Use hardware wallet for mainnet**
   - Ledger Nano S/X
   - Remote signer on air-gapped machine

2. **Configure strict RPC ACL**
   - Localhost only for solo bakers
   - Whitelist for monitoring

3. **Enable firewall with minimal rules**
   - Only open required ports
   - Block everything else

4. **Use SSH keys only**
   - Disable password auth
   - 4096-bit RSA or Ed25519 keys

5. **Apply security updates automatically**
   - `unattended-upgrades` on Ubuntu
   - Monitor for critical updates

6. **Run with non-root user**
   - `docker` group membership
   - Rootless Docker (advanced)

7. **Test recovery procedures**
   - Simulate failures
   - Verify backups work

8. **Monitor continuously**
   - Uptime monitoring
   - Alert on anomalies

---

## Emergency Response

### If Node is Under Attack

```bash
# 1. Stop node immediately
npm run node:stop

# 2. Configure localhost-only RPC
npm run security:configure-acl  # Choose option 1

# 3. Enable firewall (if not already)
sudo ufw enable
sudo ufw deny 8732

# 4. Check for compromise
sudo grep "8732" /var/log/nginx/access.log | grep -v "127.0.0.1"

# 5. Review connections
sudo netstat -an | grep 8732

# 6. Restart with secure config
npm run node:restart

# 7. Monitor closely
npm run node:logs
```

### If Keys are Compromised

**Testnet:**
1. Generate new keys
2. Transfer funds to new account
3. Update delegation

**Mainnet:**
1. **IMMEDIATE**: Transfer all funds to safe wallet
2. Contact delegators
3. Investigate how keys were compromised
4. Set up new baker with hardware wallet
5. Report incident if applicable

---

## Security Resources

### Official Documentation
- Tezos Security Guide: https://tezos.gitlab.io/introduction/howtoget.html#security
- Octez RPC ACL: https://tezos.gitlab.io/user/node-configuration.html#rpc
- Node Configuration: https://tezos.gitlab.io/user/node-configuration.html

### Tools
- Ledger Hardware Wallet: https://www.ledger.com/
- WireGuard VPN: https://www.wireguard.com/
- Fail2ban: https://www.fail2ban.org/
- UFW: https://help.ubuntu.com/community/UFW

### Community
- Tezos Baking Slack: https://tezos-dev.slack.com/
- r/tezos Security: https://reddit.com/r/tezos
- Tezos Agora: https://forum.tezosagora.org/

---

**Last Updated:** 2024-12-19
**Tezos Protocol:** Quebec (PtSeouLouX)
**Octez Version:** 23.1
