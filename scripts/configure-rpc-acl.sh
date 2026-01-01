#!/usr/bin/env bash

# RPC ACL Configuration Script
# Helps configure secure RPC access for production

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Tezos Node RPC ACL Configuration${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""

# Check if config exists
if [ ! -f "data/config.json" ]; then
    echo -e "${RED}Error: data/config.json not found${NC}"
    echo "Run 'npm run node:init' first"
    exit 1
fi

echo "Current RPC configuration:"
echo ""
jq '.rpc' data/config.json
echo ""

echo -e "${YELLOW}Choose RPC ACL configuration:${NC}"
echo ""
echo "1) Localhost only (Most Secure - recommended for single-server)"
echo "   → Only accessible from the same machine"
echo "   → Best for solo bakers"
echo ""
echo "2) Whitelist specific IPs (Secure - for remote access)"
echo "   → Only listed IP addresses can access"
echo "   → Good for monitoring/multi-server setups"
echo ""
echo "3) Current network only (Moderate - for VPN/private networks)"
echo "   → Accessible within current network"
echo "   → Use with VPN or private cloud"
echo ""
echo "4) Open to all (Dangerous - testnet only)"
echo "   → Current configuration"
echo "   → Never use on mainnet with real funds"
echo ""
echo "5) Show security examples and exit"
echo ""
read -p "Select option (1-5): " choice

case $choice in
    1)
        echo ""
        echo -e "${GREEN}Configuring: Localhost only${NC}"
        
        # Backup current config
        cp data/config.json data/config.json.backup
        
        # Update config - localhost only
        jq '.rpc = {
            "listen-addrs": ["127.0.0.1:8732"]
        }' data/config.json > data/config.json.tmp
        mv data/config.json.tmp data/config.json
        
        echo -e "${GREEN}✓ Configuration updated${NC}"
        echo ""
        echo "RPC now accessible only from localhost (127.0.0.1)"
        echo "Backup saved: data/config.json.backup"
        echo ""
        echo -e "${YELLOW}⚠️  Restart node to apply changes:${NC}"
        echo "   npm run node:restart"
        ;;
        
    2)
        echo ""
        echo -e "${GREEN}Configuring: Whitelist specific IPs${NC}"
        echo ""
        echo "Enter IP addresses to whitelist (one per line, empty line to finish):"
        
        IPS=()
        while true; do
            read -p "IP address: " ip
            if [ -z "$ip" ]; then
                break
            fi
            # Validate IP format (basic check)
            if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                IPS+=("$ip")
                echo -e "${GREEN}  ✓ Added: $ip${NC}"
            else
                echo -e "${RED}  ✗ Invalid IP format: $ip${NC}"
            fi
        done
        
        if [ ${#IPS[@]} -eq 0 ]; then
            echo -e "${RED}No IPs provided. Cancelling.${NC}"
            exit 1
        fi
        
        # Backup current config
        cp data/config.json data/config.json.backup
        
        # Build ACL array
        ACL_ARRAY="["
        for ip in "${IPS[@]}"; do
            ACL_ARRAY="${ACL_ARRAY}{\"address\": \"$ip\", \"blacklist\": []},"
        done
        ACL_ARRAY="${ACL_ARRAY%,}]"  # Remove trailing comma
        
        # Update config
        jq --argjson acl "$ACL_ARRAY" '.rpc = {
            "listen-addrs": ["0.0.0.0:8732"],
            "acl": $acl
        }' data/config.json > data/config.json.tmp
        mv data/config.json.tmp data/config.json
        
        echo ""
        echo -e "${GREEN}✓ Configuration updated${NC}"
        echo "Whitelisted IPs: ${IPS[@]}"
        echo "Backup saved: data/config.json.backup"
        echo ""
        echo -e "${YELLOW}⚠️  Restart node to apply changes:${NC}"
        echo "   npm run node:restart"
        ;;
        
    3)
        echo ""
        echo -e "${YELLOW}Detecting current network...${NC}"
        
        # Get current IP
        CURRENT_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}')
        NETWORK=$(echo $CURRENT_IP | cut -d. -f1-3).0/24
        
        echo "Current IP: $CURRENT_IP"
        echo "Network: $NETWORK"
        echo ""
        read -p "Allow access from this network? (y/n): " confirm
        
        if [ "$confirm" != "y" ]; then
            echo "Cancelled."
            exit 0
        fi
        
        # Backup current config
        cp data/config.json data/config.json.backup
        
        # Update config - current network
        NETWORK_IP=$(echo $CURRENT_IP | cut -d. -f1-3).0
        jq --arg ip "$NETWORK_IP" '.rpc = {
            "listen-addrs": ["0.0.0.0:8732"],
            "acl": [{
                "address": $ip,
                "blacklist": []
            }]
        }' data/config.json > data/config.json.tmp
        mv data/config.json.tmp data/config.json
        
        echo ""
        echo -e "${GREEN}✓ Configuration updated${NC}"
        echo "Allowed network: $NETWORK"
        echo "Backup saved: data/config.json.backup"
        echo ""
        echo -e "${YELLOW}⚠️  Restart node to apply changes:${NC}"
        echo "   npm run node:restart"
        ;;
        
    4)
        echo ""
        echo -e "${RED}⚠️  WARNING: Open to all (0.0.0.0)${NC}"
        echo ""
        echo "This configuration allows ANYONE to access your RPC endpoint."
        echo ""
        echo -e "${RED}NEVER use this on mainnet with real funds!${NC}"
        echo ""
        read -p "Are you sure? Type 'testnet only' to confirm: " confirm
        
        if [ "$confirm" != "testnet only" ]; then
            echo "Cancelled."
            exit 0
        fi
        
        # Backup current config
        cp data/config.json data/config.json.backup
        
        # Update config - open to all
        jq '.rpc = {
            "listen-addrs": ["0.0.0.0:8732"],
            "acl": [{
                "address": "0.0.0.0",
                "blacklist": []
            }]
        }' data/config.json > data/config.json.tmp
        mv data/config.json.tmp data/config.json
        
        echo ""
        echo -e "${GREEN}✓ Configuration updated${NC}"
        echo "RPC open to all addresses (0.0.0.0)"
        echo "Backup saved: data/config.json.backup"
        echo ""
        echo -e "${YELLOW}⚠️  Restart node to apply changes:${NC}"
        echo "   npm run node:restart"
        ;;
        
    5)
        echo ""
        echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
        echo -e "${BLUE}  Security Configuration Examples${NC}"
        echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
        echo ""
        
        echo -e "${GREEN}1. Localhost Only (Most Secure)${NC}"
        echo "Best for: Solo bakers on single server"
        cat << 'EXAMPLE1'
{
  "rpc": {
    "listen-addrs": ["127.0.0.1:8732"]
  }
}

Access: Only from the same machine
Commands work: docker exec, local curl
Remote access: No
EXAMPLE1
        
        echo ""
        echo -e "${GREEN}2. Whitelist Specific IPs${NC}"
        echo "Best for: Remote monitoring, multi-server setups"
        cat << 'EXAMPLE2'
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

Access: Only from 192.168.1.100 and 203.0.113.50
Remote access: Yes (from whitelisted IPs only)
EXAMPLE2
        
        echo ""
        echo -e "${GREEN}3. Private Network${NC}"
        echo "Best for: VPN, private cloud"
        cat << 'EXAMPLE3'
{
  "rpc": {
    "listen-addrs": ["10.0.0.5:8732"],
    "acl": []
  }
}

Access: Only from 10.0.0.0/8 private network
Remote access: Yes (if on VPN/private network)
EXAMPLE3
        
        echo ""
        echo -e "${GREEN}4. With Blacklist${NC}"
        echo "Best for: Allow all except specific IPs"
        cat << 'EXAMPLE4'
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

Access: All IPs except blacklisted ones
Use case: Block known attackers
EXAMPLE4
        
        echo ""
        echo -e "${YELLOW}Additional Security Layers:${NC}"
        echo ""
        echo "1. Firewall (Linux):"
        echo "   ufw allow from 192.168.1.100 to any port 8732"
        echo "   ufw deny 8732"
        echo ""
        echo "2. Reverse Proxy (nginx) with rate limiting:"
        echo "   limit_req_zone zone=rpc:10m rate=10r/s"
        echo ""
        echo "3. VPN:"
        echo "   WireGuard/OpenVPN → Node RPC"
        echo ""
        echo "4. SSH Tunnel:"
        echo "   ssh -L 8732:localhost:8732 user@node-server"
        echo ""
        ;;
        
    *)
        echo -e "${RED}Invalid option${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo "Configuration complete!"
echo ""
echo "To verify: jq '.rpc' data/config.json"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
