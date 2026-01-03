#!/bin/bash

# Polygon Node Installation Script
# Installs both Heimdall and Bor

set -e

HEIMDALL_VERSION="1.0.3"
BOR_VERSION="1.2.3"
NETWORK="mainnet"
DATA_DIR="/var/lib/polygon"

echo "Installing Polygon Node (Heimdall + Bor)..."

# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y \
    build-essential \
    git \
    curl \
    wget \
    jq \
    aria2 \
    pv

# Install Go
GO_VERSION="1.21.6"
wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
rm go${GO_VERSION}.linux-amd64.tar.gz

export PATH=$PATH:/usr/local/go/bin
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc

# Create polygon user
if ! id "polygon" &>/dev/null; then
    sudo useradd -r -m -s /bin/bash polygon
fi

# Create directories
sudo mkdir -p ${DATA_DIR}/heimdall
sudo mkdir -p ${DATA_DIR}/bor
sudo mkdir -p /var/lib/bor/data
sudo mkdir -p /var/lib/bor/keystore

# Install Heimdall
echo "Installing Heimdall ${HEIMDALL_VERSION}..."
cd /tmp
git clone https://github.com/maticnetwork/heimdall.git
cd heimdall
git checkout v${HEIMDALL_VERSION}
make install

# Initialize Heimdall
heimdalld init --chain ${NETWORK} --home ${DATA_DIR}/heimdall

# Install Bor
echo "Installing Bor ${BOR_VERSION}..."
cd /tmp
git clone https://github.com/maticnetwork/bor.git
cd bor
git checkout v${BOR_VERSION}
make bor

sudo cp build/bin/bor /usr/local/bin/

# Download genesis files
cd ${DATA_DIR}/bor
wget https://raw.githubusercontent.com/maticnetwork/bor/master/builder/files/genesis-mainnet-v1.json -O genesis.json

# Initialize Bor
bor --datadir ${DATA_DIR}/bor init ${DATA_DIR}/bor/genesis.json

# Copy configurations
sudo cp ../config/heimdall-config.toml ${DATA_DIR}/heimdall/config/config.toml
sudo cp ../config/bor-config.toml ${DATA_DIR}/bor/config.toml

# Set ownership
sudo chown -R polygon:polygon ${DATA_DIR}
sudo chown -R polygon:polygon /var/lib/bor

# Install systemd services
sudo cp ../systemd/heimdalld.service /etc/systemd/system/
sudo cp ../systemd/bor.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable heimdalld
sudo systemctl enable bor

# Configure firewall
sudo ufw allow 26656/tcp
sudo ufw allow 30303/tcp
sudo ufw allow 30303/udp

# Cleanup
rm -rf /tmp/heimdall /tmp/bor

echo ""
echo "Installation complete!"
echo ""
echo "IMPORTANT: Before starting, you need to:"
echo "1. Configure Ethereum RPC URL in ${DATA_DIR}/heimdall/config/heimdall-config.toml"
echo "2. Optionally download snapshots with: ./scripts/snapshot-download.sh"
echo ""
echo "Start services:"
echo "  sudo systemctl start heimdalld"
echo "  Wait for Heimdall to sync, then:"
echo "  sudo systemctl start bor"
