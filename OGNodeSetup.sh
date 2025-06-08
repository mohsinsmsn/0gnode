#!/bin/bash

# Add 0G-Galileo-Testnet chain from here: https://docs.0g.ai/run-a-node/testnet-information
# Faucet: https://faucet.0g.ai/

set -euo pipefail

# Update & install dependencies


# Download fresh config
CONFIG_PATH="$HOME/0g-storage-node/run/config.toml"
rm -rf "$CONFIG_PATH"
mkdir -p "$(dirname "$CONFIG_PATH")"
curl -o "$CONFIG_PATH" https://raw.githubusercontent.com/mohsinsmsn/0gnode/refs/heads/main/config.toml

# Prompt user for private key
exec < /dev/tty
echo ""
echo "👉 Enter your private key (must start with 0x and be 66 characters long):"
read -e -p "Private Key: " PRIVATE_KEY

# Keep asking until valid input is received
while [[ ! "$PRIVATE_KEY" =~ ^0x[a-fA-F0-9]{64}$ ]]; do
  echo "❌ Invalid private key format. Must start with 0x and be 66 characters long."
  read -e -p "Please re-enter your private key: " PRIVATE_KEY
done

# Update the miner_key in config.toml
if grep -q "^miner_key" "$CONFIG_PATH"; then
  sed -i "s/^miner_key.*/miner_key = \"$PRIVATE_KEY\"/" "$CONFIG_PATH"
else
  echo "miner_key = \"$PRIVATE_KEY\"" >> "$CONFIG_PATH"
fi

echo "✅ Private key successfully updated in config.toml"

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

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable zgs
sudo systemctl start zgs

echo "🚀 ZGS Node has been installed and started successfully!"
