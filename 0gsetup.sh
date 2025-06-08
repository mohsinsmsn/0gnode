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
curl -o $HOME/0g-storage-node/run/config.toml https://raw.githubusercontent.com/Mayankgg01/0G-Storage-Node-Guide/main/config.toml
