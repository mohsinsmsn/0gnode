#!/bin/bash

#Add 0G-Galileo-Testnet chain from here: https://docs.0g.ai/run-a-node/testnet-information

# Faucet: https://faucet.0g.ai/

sudo apt-get update && sudo apt-get upgrade -y
sudo apt install curl iptables build-essential git wget lz4 jq make cmake gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev screen ufw -y
curl https://sh.rustup.rs -sSf | sh
source $HOME/.cargo/env
rustc --version
go version
git clone https://github.com/0glabs/0g-storage-node.git
cd 0g-storage-node && git checkout v1.0.0 && git submodule update --init
cargo build --release
rm -rf $HOME/0g-storage-node/run/config.toml
curl -o $HOME/0g-storage-node/run/config.toml https://raw.githubusercontent.com/mohsinsmsn/0gnode/refs/heads/main/config.toml

#Enter your Private Key with 0x as prefix
nano $HOME/0g-storage-node/run/config.toml

#System Service
sudo tee /etc/systemd/system/zgs.service > /dev/null <<EOF
[Unit]
Description=ZGS Node
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/0g-storage-node/run
ExecStart=$HOME/0g-storage-node/target/release/zgs_node --config $HOME/0g-storage-node/run/config.toml
Restart=on-failure
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable zgs
sudo systemctl start zgs

