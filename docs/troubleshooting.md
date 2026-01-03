# Polygon Node Troubleshooting

## Common Issues

### Heimdall Not Syncing

**Symptom**: Heimdall stays stuck or syncs very slowly

**Solutions**:
1. Verify Ethereum RPC endpoint is accessible and synced
2. Check network connectivity to seed nodes
3. Ensure firewall allows port 26656
4. Try downloading a snapshot

```bash
# Check Heimdall status
curl localhost:26657/status | jq '.result.sync_info'

# Check peers
curl localhost:26657/net_info | jq '.result.n_peers'
```

### Bor Not Starting

**Symptom**: Bor fails to start or crashes

**Solutions**:
1. Ensure Heimdall is running and responding
2. Check Heimdall REST API is accessible at port 1317
3. Verify genesis file is correct
4. Check available disk space

```bash
# Test Heimdall API
curl localhost:1317/bor/span/1

# Check Bor logs
sudo journalctl -u bor -f
```

### Bor Cannot Connect to Heimdall

**Symptom**: Bor logs show Heimdall connection errors

**Solutions**:
1. Verify Heimdall REST server is running on port 1317
2. Check network connectivity between services
3. Ensure correct Heimdall URL in Bor config

```bash
# Check Heimdall REST API
curl http://localhost:1317/node_info
```

### Out of Disk Space

**Symptom**: Node crashes with disk full errors

**Solutions**:
1. Enable pruning in Bor
2. Clear old logs
3. Expand storage
4. Consider running pruned node instead of archive

### High Memory Usage

**Symptom**: System becomes unresponsive

**Solutions**:
1. Reduce cache settings in Bor
2. Limit mempool size
3. Add more RAM or enable swap

### Slow Synchronization

**Symptom**: Sync takes too long

**Solutions**:
1. Download snapshots from official sources
2. Ensure SSD storage is being used
3. Increase cache settings if RAM available
4. Check network bandwidth

## Snapshot Recovery

If database becomes corrupted:

```bash
# Stop services
sudo systemctl stop bor
sudo systemctl stop heimdalld

# Clear data
rm -rf /var/lib/polygon/heimdall/data/*
rm -rf /var/lib/polygon/bor/bor/chaindata

# Download fresh snapshots
./scripts/snapshot-download.sh

# Restart
sudo systemctl start heimdalld
# Wait for Heimdall to sync
sudo systemctl start bor
```

## Useful Commands

```bash
# Check Heimdall sync
curl -s localhost:26657/status | jq '.result.sync_info.catching_up'

# Check Bor sync
curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
  localhost:8545

# Get latest block
curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  localhost:8545

# Check peer count
curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
  localhost:8545

# View logs
sudo journalctl -u heimdalld -f
sudo journalctl -u bor -f
```

## Log Locations

- Heimdall: journalctl -u heimdalld
- Bor: journalctl -u bor
- Data directories: /var/lib/polygon/
