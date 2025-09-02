# PersonaForge UI - React Frontend

A React.js frontend for interacting with PersonaForge Intelligent NFTs on the 0G Network.

## Features

- 🔗 **Wallet Connection** - Connect with RainbowKit (MetaMask, WalletConnect, etc.)
- 🎨 **Create Persona Groups** - Set up AI personas with encrypted storage
- 🖼️ **Mint INFTs** - Create Intelligent NFTs that grant AI agent access
- 💾 **Storage Management** - Update and manage encrypted persona data
- 🤖 **AI Chat Interface** - Interact with AI agents through your INFTs
- 📱 **Responsive Design** - Works on desktop and mobile devices

## Tech Stack

- **React.js 18** - Frontend framework
- **Wagmi v2** - Ethereum React hooks
- **Viem** - TypeScript interface for Ethereum
- **RainbowKit** - Wallet connection UI
- **TailwindCSS** - Styling framework
- **Heroicons** - Icon library
- **React Hot Toast** - Notifications

## Quick Start

### 1. Install Dependencies

```bash
cd app
npm install
```

### 2. Configure Environment

Copy the environment template and fill in your values:

```bash
cp env.example .env
```

Edit `.env` with your configuration:

```env
# 0G Network Configuration
REACT_APP_OG_RPC_URL=https://evmrpc-testnet.0g.ai
REACT_APP_OG_CHAIN_ID=16600

# Contract Addresses (fill after deployment)
REACT_APP_PERSONA_INFT_ADDRESS=0x...
REACT_APP_STORAGE_MANAGER_ADDRESS=0x...
REACT_APP_AGENT_MANAGER_ADDRESS=0x...

# WalletConnect Project ID
REACT_APP_WALLETCONNECT_PROJECT_ID=your-project-id
```

### 3. Deploy Contracts First

Make sure you've deployed the PersonaForge contracts:

```bash
cd ../
forge script contracts/script/Deploy.s.sol --rpc-url og_testnet --broadcast
```

Update the `.env` file with the deployed contract addresses.

### 4. Start Development Server

```bash
npm start
```

The app will be available at `http://localhost:3000`

## Environment Variables

| Variable                             | Description                     | Required |
| ------------------------------------ | ------------------------------- | -------- |
| `REACT_APP_OG_RPC_URL`               | 0G Network RPC URL              | Yes      |
| `REACT_APP_OG_CHAIN_ID`              | 0G Chain ID (16600 for testnet) | Yes      |
| `REACT_APP_PERSONA_INFT_ADDRESS`     | PersonaINFT contract address    | Yes      |
| `REACT_APP_STORAGE_MANAGER_ADDRESS`  | StorageManager contract address | Yes      |
| `REACT_APP_AGENT_MANAGER_ADDRESS`    | AgentManager contract address   | Yes      |
| `REACT_APP_WALLETCONNECT_PROJECT_ID` | WalletConnect project ID        | Yes      |
| `REACT_APP_OG_STORAGE_URL`           | 0G Storage API URL              | No       |
| `REACT_APP_OG_COMPUTE_URL`           | 0G Compute API URL              | No       |

## Getting Required IDs

### WalletConnect Project ID

1. Go to [WalletConnect Cloud](https://cloud.walletconnect.com/)
2. Create a new project
3. Copy the Project ID

### Contract Addresses

Deploy the contracts using the provided Foundry scripts and copy the addresses from the deployment output.

## Usage Guide

### 1. Connect Wallet

- Click "Connect Wallet" in the top right
- Select your preferred wallet (MetaMask, WalletConnect, etc.)
- Make sure you're on the 0G Newton Testnet

### 2. Create Persona Group

- Go to "Create Group" tab
- Fill in persona name, description, and personality data
- Click "Create Persona Group"
- Note the Group ID from the transaction

### 3. Mint PersonaINFT

- Go to "Mint INFT" tab
- Enter recipient address and Group ID
- Add individual personality traits
- Click "Mint PersonaINFT"

### 4. Manage Storage

- Go to "Storage" tab
- Create new storage groups or update existing ones
- All data is encrypted before storage

### 5. Chat with AI

- Go to "AI Chat" tab
- Select your PersonaINFT from dropdown
- Start chatting with your AI agent!

## Project Structure

```
app/
├── public/                 # Static files
├── src/
│   ├── components/        # React components
│   │   ├── Header.js      # Navigation header
│   │   ├── Dashboard.js   # Main dashboard
│   │   ├── CreatePersonaGroup.js
│   │   ├── MintPersonaINFT.js
│   │   ├── StorageManager.js
│   │   ├── AIInteraction.js
│   │   └── MyINFTs.js
│   ├── config/           # Configuration files
│   │   ├── contracts.js  # Contract ABIs and addresses
│   │   └── wagmi.js      # Wagmi configuration
│   ├── App.js           # Main app component
│   ├── App.css          # Global styles
│   └── index.js         # Entry point
├── package.json
├── tailwind.config.js
└── README.md
```

## Available Scripts

- `npm start` - Start development server
- `npm run build` - Build for production
- `npm test` - Run tests
- `npm run eject` - Eject from Create React App

## Troubleshooting

### Common Issues

1. **"Contract address not configured"**

   - Make sure you've set the contract addresses in `.env`
   - Verify the contracts are deployed on the correct network

2. **"Network not supported"**

   - Check that your wallet is connected to 0G Newton Testnet
   - Verify the RPC URL and Chain ID in `.env`

3. **"Transaction failed"**

   - Ensure you have enough 0G tokens for gas
   - Check that you're calling functions with correct parameters

4. **Wallet connection issues**
   - Make sure you have a valid WalletConnect Project ID
   - Try refreshing the page and reconnecting

### Network Configuration

Add 0G Newton Testnet to your wallet:

- **Network Name**: 0G Newton Testnet
- **RPC URL**: https://evmrpc-testnet.0g.ai
- **Chain ID**: 16600
- **Currency Symbol**: 0G
- **Block Explorer**: https://explorer-testnet.0g.ai

## Development

### Adding New Components

1. Create component in `src/components/`
2. Import and use in `Dashboard.js` or other parent components
3. Add any new contract interactions to `config/contracts.js`

### Updating Contract ABIs

When contracts change:

1. Update the ABIs in `src/config/contracts.js`
2. Update contract addresses in `.env`
3. Test all functionality

### Styling

This project uses TailwindCSS for styling:

- Custom styles in `src/App.css`
- Tailwind configuration in `tailwind.config.js`
- Component styles use Tailwind classes

## Production Deployment

### Build for Production

```bash
npm run build
```

### Deploy to Hosting

The built files in the `build/` directory can be deployed to:

- Vercel
- Netlify
- AWS S3 + CloudFront
- Any static hosting service

### Environment Variables for Production

Make sure to set production environment variables:

- Use mainnet contract addresses
- Use production 0G RPC URLs
- Set appropriate API keys

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

MIT License - see LICENSE file for details.
