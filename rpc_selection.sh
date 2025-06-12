#!/bin/bash


# Download fresh config
CONFIG_PATH="$HOME/0g-storage-node/run/config.toml"
mkdir -p "$(dirname "$CONFIG_PATH")"
curl -o "$CONFIG_PATH" https://raw.githubusercontent.com/mohsinsmsn/0gnode/refs/heads/main/config.toml

# Prompt user for private key
exec < /dev/tty


# Prompt for and measure RPCs
echo ""
echo "🌐 Measuring RPC Endpoint ping times... Please wait."

declare -a RPC_LIST=(
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

declare -a SORTED_RPCS

# Measure ping time via curl
for RPC in "${RPC_LIST[@]}"; do
  TIME_S=$(curl -o /dev/null -s -w "%{time_total}" --connect-timeout 2 "$RPC")
  if [[ -z "$TIME_S" || "$TIME_S" == "000" ]]; then
    TIME_MS=99999
  else
    TIME_MS=$(awk "BEGIN { printf \"%.0f\", $TIME_S * 1000 }")
  fi
  SORTED_RPCS+=("${TIME_MS}|${RPC}")
done

# Sort RPCs by ping time
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
done

echo ""
read -p "📡 Choose the RPC number to use (e.g., 0): " RPC_CHOICE

CHOSEN_RPC=$(echo "${SORTED_RPCS[$RPC_CHOICE]}" | cut -d'|' -f2)

# Update blockchain_rpc_endpoint
if grep -q "^blockchain_rpc_endpoint" "$CONFIG_PATH"; then
  sed -i "s|^blockchain_rpc_endpoint.*|blockchain_rpc_endpoint = \"${CHOSEN_RPC}\"|" "$CONFIG_PATH"
else
  echo "blockchain_rpc_endpoint = \"${CHOSEN_RPC}\"" >> "$CONFIG_PATH"
fi

echo "✅ RPC endpoint successfully set to:"
echo "\"$CHOSEN_RPC\""
