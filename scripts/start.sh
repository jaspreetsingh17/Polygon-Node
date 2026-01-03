#!/bin/bash

# Start Polygon Node (Heimdall + Bor)

set -e

DATA_DIR="/var/lib/polygon"

echo "Starting Polygon Node..."

# Check if Ethereum RPC is configured
if grep -q "http://localhost:8545" ${DATA_DIR}/heimdall/config/heimdall-config.toml; then
    echo "WARNING: Ethereum RPC URL appears to be default localhost"
    echo "Make sure you have an Ethereum node running or update the RPC URL"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Start Heimdall first
echo "Starting Heimdall..."
sudo systemctl start heimdalld

# Wait for Heimdall to start
echo "Waiting for Heimdall to initialize..."
sleep 30

# Check Heimdall status
if ! systemctl is-active --quiet heimdalld; then
    echo "ERROR: Heimdall failed to start"
    sudo journalctl -u heimdalld --no-pager -n 50
    exit 1
fi

# Check Heimdall sync status
echo "Checking Heimdall sync status..."
HEIMDALL_STATUS=$(curl -s http://localhost:26657/status)
CATCHING_UP=$(echo $HEIMDALL_STATUS | jq -r '.result.sync_info.catching_up')

if [ "$CATCHING_UP" == "true" ]; then
    echo "Heimdall is still syncing. Bor will start but may not function until Heimdall catches up."
fi

# Start Bor
echo "Starting Bor..."
sudo systemctl start bor

sleep 10

# Check Bor status
if systemctl is-active --quiet bor; then
    echo "Bor started successfully"
else
    echo "ERROR: Bor failed to start"
    sudo journalctl -u bor --no-pager -n 50
    exit 1
fi

echo ""
echo "Both services started!"
echo ""
echo "Monitor logs:"
echo "  Heimdall: sudo journalctl -u heimdalld -f"
echo "  Bor: sudo journalctl -u bor -f"
echo ""
echo "Check sync status:"
echo "  Heimdall: curl localhost:26657/status | jq '.result.sync_info'"
echo "  Bor: curl -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"eth_syncing\",\"params\":[],\"id\":1}' localhost:8545"
