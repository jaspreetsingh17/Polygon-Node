# Polygon Bor Full Node Deployment

A complete guide for deploying a Polygon PoS (Proof of Stake) full node using Bor and Heimdall.

## Overview

Polygon is a Layer 2 scaling solution for Ethereum. Running a Polygon full node requires two components:
- **Heimdall**: The validator layer that handles Proof of Stake consensus
- **Bor**: The block producer layer that is EVM-compatible

## Requirements

- Ubuntu 22.04 LTS
- 8 CPU cores (16 recommended)
- 32GB RAM minimum (64GB recommended)
- 2TB SSD storage
- 100 Mbps network connection

## Architecture

```
                +------------------+
                |    Ethereum      |
                |    Full Node     |
                |    (Required)    |
                +--------+---------+
                         |
            RPC Connection (8545)
                         |
                +--------+---------+
                |    Heimdall      |
                |    (Consensus)   |
                +--------+---------+
                         |
                  Internal API
                         |
                +--------+---------+
                |      Bor         |
                |   (Execution)    |
                +------------------+
```

## Quick Start

```bash
git clone https://github.com/your-username/polygon-bor-node.git
cd polygon-bor-node
chmod +x scripts/install.sh
./scripts/install.sh
```

## Directory Structure

```
.
├── config/
│   ├── heimdall-config.toml
│   └── bor-config.toml
├── scripts/
│   ├── install.sh
│   ├── start.sh
│   ├── snapshot-download.sh
│   └── monitor.sh
├── docker/
│   └── docker-compose.yml
├── systemd/
│   ├── heimdalld.service
│   └── bor.service
└── docs/
    └── troubleshooting.md
```

## Prerequisites

You need access to an Ethereum mainnet full node RPC endpoint. This can be:
- Your own Ethereum node
- A third-party provider (Infura, Alchemy, etc.)

## Ports

| Port | Service | Purpose |
|------|---------|---------|
| 26656 | Heimdall | P2P |
| 26657 | Heimdall | RPC |
| 1317 | Heimdall | REST API |
| 30303 | Bor | P2P |
| 8545 | Bor | HTTP RPC |
| 8546 | Bor | WebSocket |

## Sync Time

Using snapshots, synchronization takes approximately 24-48 hours. Without snapshots, full sync can take several weeks.

## License

MIT License
