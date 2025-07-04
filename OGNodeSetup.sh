#!/bin/bash



# Download fresh config
CONFIG_PATH="$HOME/0g-storage-node/run/config.toml"
rm -rf "$CONFIG_PATH"
mkdir -p "$(dirname "$CONFIG_PATH")"
curl -o "$CONFIG_PATH" https://raw.githubusercontent.com/mohsinsmsn/0gnode/refs/heads/main/config.toml

# Prompt user for private key (64 hex chars, no 0x)
exec < /dev/tty
echo ""
echo "🔐 Enter your private key (exactly 64 hex characters, without 0x):"
read -e -p "Private Key: " PRIVATE_KEY

while [[ ! "$PRIVATE_KEY" =~ ^[a-fA-F0-9]{64}$ ]]; do
  echo "❌ Invalid private key format. Please enter exactly 64 hex characters (no 0x)."
  read -e -p "Re-enter Private Key: " PRIVATE_KEY
done

# Update miner_key in config.toml
if grep -q "^miner_key" "$CONFIG_PATH"; then
  sed -i "s|^miner_key.*|miner_key = \"$PRIVATE_KEY\"|" "$CONFIG_PATH"
else
  echo "miner_key = \"$PRIVATE_KEY\"" >> "$CONFIG_PATH"
fi

echo "✅ Private key successfully updated in config.toml"

# RPC selection
echo ""
echo "🌐 Available RPC Endpoints:"
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

for i in "${!RPC_LIST[@]}"; do
  echo "[$i] ${RPC_LIST[$i]}"
done

echo ""
read -p "Enter the number of the RPC you'd like to use: " RPC_INDEX

while ! [[ "$RPC_INDEX" =~ ^[0-9]+$ ]] || (( RPC_INDEX < 0 || RPC_INDEX >= ${#RPC_LIST[@]} )); do
  echo "❌ Invalid input. Please enter a number between 0 and $(( ${#RPC_LIST[@]} - 1 ))."
  read -p "Enter the number of the RPC you'd like to use: " RPC_INDEX
done

CHOSEN_RPC="${RPC_LIST[$RPC_INDEX]}"

# Update blockchain_rpc_endpoint in config.toml
if grep -q "^blockchain_rpc_endpoint" "$CONFIG_PATH"; then
  sed -i "s|^blockchain_rpc_endpoint.*|blockchain_rpc_endpoint = \"$CHOSEN_RPC\"|" "$CONFIG_PATH"
else
  echo "blockchain_rpc_endpoint = \"$CHOSEN_RPC\"" >> "$CONFIG_PATH"
fi

echo "✅ RPC endpoint updated to: $CHOSEN_RPC"

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

echo ""
echo "🚀 ZGS Node has been installed and started successfully!"
echo "🔍 To view logs: journalctl -u zgs -f"
