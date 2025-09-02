import { getDefaultConfig } from "@rainbow-me/rainbowkit";
import { SUPPORTED_CHAINS } from "./contracts";

export const wagmiConfig = getDefaultConfig({
  appName: "PersonaForge",
  projectId:
    process.env.REACT_APP_WALLETCONNECT_PROJECT_ID || "your-project-id",
  chains: SUPPORTED_CHAINS,
  ssr: false, // If your dApp uses server side rendering (SSR)
});
