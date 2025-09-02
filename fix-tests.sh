#!/bin/bash

echo "Fixing test compilation issues..."

# Replace InteractionLog with correct struct names
find contracts/test -name "*.sol" -exec sed -i '' 's/PersonaAgentManager\.InteractionLog/IPersonaAgent.AgentRequest/g' {} \;
find contracts/test -name "*.sol" -exec sed -i '' 's/InteractionLog/AgentRequest/g' {} \;

# Fix getInteractionHistory calls - this function returns two arrays
find contracts/test -name "*.sol" -exec sed -i '' 's/agentManager\.getInteractionHistory(\([^)]*\))/agentManager.getInteractionHistory(\1)/g' {} \;

echo "Test fixes applied!"
