#!/bin/bash

# Polygon Node Monitoring Script

while true; do
    clear
    echo "=========================================="
    echo "       Polygon Node Monitor"
    echo "=========================================="
    echo ""
    
    # Heimdall Status
    echo "HEIMDALL"
    echo "--------"
    if systemctl is-active --quiet heimdalld; then
        echo "Status: Running"
        
        HEIMDALL_STATUS=$(curl -s http://localhost:26657/status 2>/dev/null)
        if [ -n "$HEIMDALL_STATUS" ]; then
            LATEST_BLOCK=$(echo $HEIMDALL_STATUS | jq -r '.result.sync_info.latest_block_height')
            CATCHING_UP=$(echo $HEIMDALL_STATUS | jq -r '.result.sync_info.catching_up')
            echo "Latest Block: ${LATEST_BLOCK}"
            echo "Syncing: ${CATCHING_UP}"
        else
            echo "RPC not responding"
        fi
    else
        echo "Status: NOT RUNNING"
    fi
    echo ""
    
    # Bor Status
    echo "BOR"
    echo "---"
    if systemctl is-active --quiet bor; then
        echo "Status: Running"
        
        # Get sync status
        SYNC_RESULT=$(curl -s -H "Content-Type: application/json" \
            -d '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
            http://localhost:8545 2>/dev/null)
        
        if [ -n "$SYNC_RESULT" ]; then
            SYNCING=$(echo $SYNC_RESULT | jq -r '.result')
            if [ "$SYNCING" == "false" ]; then
                echo "Sync: Complete"
                
                BLOCK_RESULT=$(curl -s -H "Content-Type: application/json" \
                    -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
                    http://localhost:8545 2>/dev/null)
                BLOCK_HEX=$(echo $BLOCK_RESULT | jq -r '.result')
                BLOCK_DEC=$((16#${BLOCK_HEX:2}))
                echo "Current Block: ${BLOCK_DEC}"
            else
                CURRENT=$(echo $SYNC_RESULT | jq -r '.result.currentBlock')
                HIGHEST=$(echo $SYNC_RESULT | jq -r '.result.highestBlock')
                echo "Syncing: ${CURRENT} / ${HIGHEST}"
            fi
        else
            echo "RPC not responding"
        fi
        
        # Peer count
        PEER_RESULT=$(curl -s -H "Content-Type: application/json" \
            -d '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
            http://localhost:8545 2>/dev/null)
        if [ -n "$PEER_RESULT" ]; then
            PEER_HEX=$(echo $PEER_RESULT | jq -r '.result')
            PEER_COUNT=$((16#${PEER_HEX:2}))
            echo "Peers: ${PEER_COUNT}"
        fi
    else
        echo "Status: NOT RUNNING"
    fi
    echo ""
    
    # System Resources
    echo "SYSTEM RESOURCES"
    echo "----------------"
    
    HEIMDALL_PID=$(pgrep -x heimdalld 2>/dev/null)
    BOR_PID=$(pgrep -x bor 2>/dev/null)
    
    if [ -n "$HEIMDALL_PID" ]; then
        HEIMDALL_MEM=$(ps -p $HEIMDALL_PID -o rss= 2>/dev/null)
        echo "Heimdall Memory: $((HEIMDALL_MEM/1024)) MB"
    fi
    
    if [ -n "$BOR_PID" ]; then
        BOR_MEM=$(ps -p $BOR_PID -o rss= 2>/dev/null)
        echo "Bor Memory: $((BOR_MEM/1024)) MB"
    fi
    
    echo ""
    echo "Disk Usage:"
    df -h /var/lib/polygon 2>/dev/null | tail -1 | awk '{print "  " $3 " / " $2 " (" $5 " used)"}'
    
    echo ""
    echo "Last updated: $(date)"
    echo "Press Ctrl+C to exit"
    
    sleep 30
done
