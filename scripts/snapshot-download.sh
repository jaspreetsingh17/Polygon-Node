#!/bin/bash

# Polygon Snapshot Download Script
# Downloads pre-synced blockchain data to speed up initial sync

set -e

DATA_DIR="/var/lib/polygon"
SNAPSHOT_URL_HEIMDALL="https://snapshot-download.polygon.technology/heimdall-mainnet-snapshot"
SNAPSHOT_URL_BOR="https://snapshot-download.polygon.technology/bor-mainnet-snapshot"

echo "Polygon Snapshot Download"
echo "========================="
echo ""
echo "This will download and extract blockchain snapshots."
echo "This process requires significant disk space and bandwidth."
echo ""

# Check disk space
AVAILABLE=$(df -BG ${DATA_DIR} | tail -1 | awk '{print $4}' | sed 's/G//')
echo "Available disk space: ${AVAILABLE}GB"
echo "Required: ~1.5TB for full extraction"
echo ""

read -p "Continue with download? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

# Stop services if running
echo "Stopping services..."
sudo systemctl stop bor 2>/dev/null || true
sudo systemctl stop heimdalld 2>/dev/null || true

# Download Heimdall snapshot
echo ""
echo "Downloading Heimdall snapshot..."
echo "This may take several hours depending on your connection."

cd ${DATA_DIR}
rm -rf heimdall/data

# Use aria2 for faster download
aria2c -x 16 -s 16 -d ${DATA_DIR} -o heimdall-snapshot.tar.gz ${SNAPSHOT_URL_HEIMDALL}

echo "Extracting Heimdall snapshot..."
tar -xzf heimdall-snapshot.tar.gz -C heimdall/
rm heimdall-snapshot.tar.gz

# Download Bor snapshot
echo ""
echo "Downloading Bor snapshot..."
rm -rf bor/bor/chaindata

aria2c -x 16 -s 16 -d ${DATA_DIR} -o bor-snapshot.tar.gz ${SNAPSHOT_URL_BOR}

echo "Extracting Bor snapshot..."
tar -xzf bor-snapshot.tar.gz -C bor/
rm bor-snapshot.tar.gz

# Set permissions
sudo chown -R polygon:polygon ${DATA_DIR}

echo ""
echo "Snapshot extraction complete!"
echo ""
echo "You can now start the services:"
echo "  sudo systemctl start heimdalld"
echo "  sudo systemctl start bor"
