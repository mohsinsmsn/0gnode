#!/bin/bash

# 0G Storage Node Setup Script

sudo apt update -qq > /dev/null 2>&1 && \
sudo apt install -y figlet ruby > /dev/null 2>&1 && \
sudo gem install lolcat > /dev/null 2>&1 && \
figlet -f slant "Kind Crypto" | lolcat && \
sleep 5

# 0G Storage Node Setup Script (Fixed Version)
# Author: Mohsin | Modified by ChatGPT for stable prompt interaction

set -euo pipefail

# Update & install dependencies
sudo apt-get update && sudo apt-get upgrade -y
sudo apt install -y curl iptables build-essential git wget lz4 jq make cmake gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev screen ufw

# Install Rust
curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"
rustc --version || echo "Rust installation failed"

# Install Go
wget https://go.dev/dl/go1.24.3.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.24.3.linux-amd64.tar.gz
rm go1.24.3.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
export PATH=$PATH:/usr/local/go/bin
source ~/.bashrc
go version || echo "Go installation failed"

# Remove existing node dir if present
rm -rf "$HOME/0g-storage-node"

# Clone and build the node
git clone https://github.com/0glabs/0g-storage-node.git
cd 0g-storage-node
git checkout v1.0.0
git submodule update --init
cargo build --release

# Download fresh config
CONFIG_PATH="$HOME/0g-storage-node/run/config.toml"
mkdir -p "$(dirname "$CONFIG_PATH")"
curl -s -o "$CONFIG_PATH" https://raw.githubusercontent.com/mohsinsmsn/0gnode/refs/heads/main/config.toml

# Prompt user for private key with TTY-safe input
read_private_key() {
  while true; do
    read -r -p $'\n🔐 Enter your private key (64 hex chars, without 0x): ' PRIVATE_KEY </dev/tty
    if [[ "$PRIVATE_KEY" =~ ^[a-fA-F0-9]{64}$ ]]; then
      break
    else
      echo "❌ Invalid format. Please enter exactly 64 hex characters (no 0x)." >&2
    fi
  done
}
read_private_key

# Update config.toml
if grep -q "^miner_key" "$CONFIG_PATH"; then
  sed -i "s/^miner_key.*/miner_key = \"$PRIVATE_KEY\"/" "$CONFIG_PATH"
else
  echo "miner_key = \"$PRIVATE_KEY\"" >> "$CONFIG_PATH"
fi

echo -e "\n✅ Private key successfully updated in config.toml"

# Define RPC list
RPC_LIST=(
  "https://0g-evm-rpc.zeycanode.com/"
  "https://evmrpc-testnet.0g.ai"
  "https://0g-testnet-rpc.astrostake.xyz"
  "https://lightnode-json-rpc-0g.grandvalleys.com"
  "https://0g-galileo-evmrpc.corenodehq.xyz/"
  "https://0g.json-rpc.cryptomolot.com/"
  "https://0g-evm.maouam.nodelab.my.id/"
  "https://0g-evmrpc-galileo.coinsspor.com/"
  "https://0g-evmrpc-galileo.komado.xyz/"
  "https://0g.galileo.zskw.xyz/"
  "https://0g-galileo.shachopra.com/"
  "https://0g-galileo-evmrpc2.corenodehq.xyz/"
  "http://0g-galileo-evm-rpc.validator247.com/"
  "https://evmrpc.vinnodes.com/"
  "https://0g-galileo-ferdimanaa.xyz/"
  "https://0g-galileo.xzid.xyz/"
)

# Measure ping time
echo -e "\n🌐 Measuring RPC Endpoint ping times... Please wait."
SORTED_RPCS=()
for RPC in "${RPC_LIST[@]}"; do
  TIME_S=$(curl -o /dev/null -s -w "%{time_total}" --connect-timeout 2 "$RPC")
  [[ -z "$TIME_S" || "$TIME_S" == "000" ]] && TIME_MS=99999 || TIME_MS=$(awk "BEGIN { printf \"%.0f\", $TIME_S * 1000 }")
  SORTED_RPCS+=("${TIME_MS}|${RPC}")
  sleep 0.1

done
IFS=$'\n' SORTED_RPCS=($(sort -n <<<"${SORTED_RPCS[*]}"))
unset IFS

echo ""
echo "✅ RPCs sorted by ping:"
for i in "${!SORTED_RPCS[@]}"; do
  IFS="|" read -r TIME RPC <<< "${SORTED_RPCS[$i]}"
  if [[ "$TIME" == "99999" ]]; then
    echo "[$i] $RPC 🛑 timeout"
  else
    echo "[$i] $RPC 🕒 ${TIME}ms"
  fi
  sleep 0.05
done

read_rpc_choice() {
  while true; do
    read -r -p $'\n📡 Choose the RPC number to use (e.g., 0): ' RPC_CHOICE </dev/tty
    if [[ "$RPC_CHOICE" =~ ^[0-9]+$ ]] && (( RPC_CHOICE >= 0 && RPC_CHOICE < ${#SORTED_RPCS[@]} )); then
      break
    else
      echo "❌ Invalid selection. Try again." >&2
    fi
  done
}
read_rpc_choice

CHOSEN_RPC=$(echo "${SORTED_RPCS[$RPC_CHOICE]}" | cut -d'|' -f2)

if grep -q "^blockchain_rpc_endpoint" "$CONFIG_PATH"; then
  sed -i "s|^blockchain_rpc_endpoint.*|blockchain_rpc_endpoint = \"${CHOSEN_RPC}\"|" "$CONFIG_PATH"
else
  echo "blockchain_rpc_endpoint = \"${CHOSEN_RPC}\"" >> "$CONFIG_PATH"
fi

echo -e "\n✅ RPC endpoint successfully set to:\n\"$CHOSEN_RPC\""

# Create systemd service
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

echo ""
echo "🚀 ZGS Node has been installed and started successfully!"
