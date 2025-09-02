#!/bin/bash

echo "=== PersonaForge Contract Deployment ==="
echo ""

# Check if private key is provided
if [ -z "$1" ]; then
    echo "Usage: ./deploy.sh <PRIVATE_KEY>"
    echo ""
    echo "Example:"
    echo "./deploy.sh 0x1234567890abcdef..."
    echo ""
    echo "Make sure you have:"
    echo "1. 0G testnet tokens for gas fees"
    echo "2. Your wallet connected to 0G Newton Testnet"
    echo "3. Network: 0G Newton Testnet"
    echo "4. RPC URL: https://evmrpc-testnet.0g.ai"
    echo "5. Chain ID: 16600"
    exit 1
fi

PRIVATE_KEY=$1
RPC_URL="https://evmrpc-testnet.0g.ai"

echo "Deploying to 0G Newton Testnet..."
echo "RPC URL: $RPC_URL"
echo ""

# Deploy contracts
forge script contracts/script/SimpleDeploy.s.sol \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --verify \
    --legacy

echo ""
echo "Deployment complete!"
echo ""
echo "Next steps:"
echo "1. Copy the contract addresses from above"
echo "2. Add them to your app/.env file"
echo "3. Get a WalletConnect Project ID from https://cloud.walletconnect.com/"
echo "4. Start the React app with: cd app && npm start"
