import React, { useState } from "react";
import { useAccount } from "wagmi";
import {
  PlusIcon,
  CpuChipIcon,
  CloudArrowUpIcon,
  ChatBubbleLeftRightIcon,
  CalendarDaysIcon,
  EyeIcon,
} from "@heroicons/react/24/outline";

import CreatePersonaGroup from "./CreatePersonaGroup";
import MintPersonaINFT from "./MintPersonaINFT";
import StorageManager from "./StorageManager";
import SimpleAIInteraction from "./SimpleAIInteraction";
import SimpleDailySync from "./SimpleDailySync";
import SimpleAIMonitor from "./SimpleAIMonitor";
import NetworkStatus from "./NetworkStatus";
import MyINFTs from "./MyINFTs";

const Dashboard = () => {
  const { isConnected, address } = useAccount();
  const [activeTab, setActiveTab] = useState("overview");

  if (!isConnected) {
    return (
      <div className="text-center py-12">
        <div className="max-w-md mx-auto">
          <CpuChipIcon className="mx-auto h-16 w-16 text-gray-400 mb-4" />
          <h2 className="text-2xl font-bold text-gray-900 mb-2">
            Welcome to PersonaForge
          </h2>
          <p className="text-gray-600 mb-6">
            Connect your wallet to start creating and interacting with
            Intelligent NFTs powered by AI agents.
          </p>
          <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
            <p className="text-sm text-blue-800">
              <strong>Note:</strong> Make sure you're connected to the
              OG-Galileo-Testnet (Chain ID: 16601) to use this application.
            </p>
          </div>
        </div>
      </div>
    );
  }

  const tabs = [
    { id: "overview", name: "Overview", icon: CpuChipIcon },
    { id: "create-group", name: "Create Group", icon: PlusIcon },
    { id: "mint-inft", name: "Mint INFT", icon: PlusIcon },
    { id: "daily-sync", name: "Daily Sync", icon: CalendarDaysIcon },
    { id: "storage", name: "Storage", icon: CloudArrowUpIcon },
    { id: "ai-chat", name: "AI Chat", icon: ChatBubbleLeftRightIcon },
    { id: "ai-monitor", name: "AI Monitor", icon: EyeIcon },
  ];

  return (
    <div className="max-w-7xl mx-auto">
      {/* Tab Navigation */}
      <div className="border-b border-gray-200 mb-8">
        <nav className="-mb-px flex space-x-8">
          {tabs.map((tab) => {
            const Icon = tab.icon;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`${
                  activeTab === tab.id
                    ? "border-primary-500 text-primary-600"
                    : "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
                } whitespace-nowrap py-2 px-1 border-b-2 font-medium text-sm flex items-center space-x-2`}
              >
                <Icon className="h-4 w-4" />
                <span>{tab.name}</span>
              </button>
            );
          })}
        </nav>
      </div>

      {/* Network Status */}
      <div className="mb-6">
        <NetworkStatus />
      </div>

      {/* Tab Content */}
      <div className="tab-content">
        {activeTab === "overview" && <OverviewTab address={address} />}
        {activeTab === "create-group" && <CreatePersonaGroup />}
        {activeTab === "mint-inft" && <MintPersonaINFT />}
        {activeTab === "daily-sync" && <SimpleDailySync />}
        {activeTab === "storage" && <StorageManager />}
        {activeTab === "ai-chat" && <SimpleAIInteraction />}
        {activeTab === "ai-monitor" && <SimpleAIMonitor />}
      </div>
    </div>
  );
};

const OverviewTab = ({ address }) => {
  return (
    <div className="space-y-8">
      {/* Welcome Section */}
      <div className="bg-gradient-to-r from-primary-500 to-secondary-500 rounded-xl p-6 text-white">
        <h2 className="text-2xl font-bold mb-2">Welcome to PersonaForge</h2>
        <p className="text-primary-100 mb-4">
          Create, manage, and interact with AI-powered Intelligent NFTs on the
          0G Network.
        </p>
        <div className="text-sm text-primary-200">
          Connected: {address?.slice(0, 6)}...{address?.slice(-4)}
        </div>
      </div>

      {/* Quick Actions */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-6">
        <QuickActionCard
          title="Create Persona Group"
          description="Set up a new persona group with central storage"
          icon={PlusIcon}
          color="bg-blue-500"
        />
        <QuickActionCard
          title="Mint INFT"
          description="Mint a new Intelligent NFT with AI agent access"
          icon={CpuChipIcon}
          color="bg-green-500"
        />
        <QuickActionCard
          title="Daily Sync"
          description="Add daily thoughts and experiences to enhance AI"
          icon={CalendarDaysIcon}
          color="bg-indigo-500"
        />
        <QuickActionCard
          title="Manage Storage"
          description="Update and manage encrypted persona data"
          icon={CloudArrowUpIcon}
          color="bg-purple-500"
        />
        <QuickActionCard
          title="Chat with AI"
          description="Interact with your AI agents through INFTs"
          icon={ChatBubbleLeftRightIcon}
          color="bg-orange-500"
        />
        <QuickActionCard
          title="AI Monitor"
          description="Track AI requests and responses in real-time"
          icon={EyeIcon}
          color="bg-red-500"
        />
      </div>

      {/* My INFTs Section */}
      <div>
        <h3 className="text-lg font-semibold text-gray-900 mb-4">My INFTs</h3>
        <MyINFTs />
      </div>
    </div>
  );
};

const QuickActionCard = ({ title, description, icon: Icon, color }) => {
  return (
    <div className="bg-white rounded-lg border border-gray-200 p-6 card-hover">
      <div
        className={`${color} w-12 h-12 rounded-lg flex items-center justify-center mb-4`}
      >
        <Icon className="h-6 w-6 text-white" />
      </div>
      <h4 className="font-semibold text-gray-900 mb-2">{title}</h4>
      <p className="text-sm text-gray-600">{description}</p>
    </div>
  );
};

export default Dashboard;
