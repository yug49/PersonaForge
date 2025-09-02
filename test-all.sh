#!/bin/bash

echo "=== PersonaForge Comprehensive Test Suite ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Navigate to project directory
cd /Users/shubhtastic/Documents/0g/PersonaForge

echo -e "${BLUE}🔨 Building contracts...${NC}"
forge build
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Build failed!${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Build successful!${NC}"
echo ""

echo -e "${BLUE}🧪 Running Unit Tests...${NC}"
echo ""

echo -e "${YELLOW}📝 PersonaINFT Unit Tests:${NC}"
forge test --match-contract PersonaINFTTest -vv
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ PersonaINFT tests failed!${NC}"
    exit 1
fi

echo -e "${YELLOW}📝 PersonaStorageManager Unit Tests:${NC}"
forge test --match-contract PersonaStorageManagerTest -vv
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ PersonaStorageManager tests failed!${NC}"
    exit 1
fi

echo -e "${YELLOW}📝 PersonaAgentManager Unit Tests:${NC}"
forge test --match-contract PersonaAgentManagerTest -vv
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ PersonaAgentManager tests failed!${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}🔗 Running Integration Tests...${NC}"
forge test --match-contract IntegrationTest -vv
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Integration tests failed!${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}🔒 Running Invariant Tests...${NC}"
forge test --match-contract InvariantTest -vv
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Invariant tests failed!${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}⚡ Running Edge Case Tests...${NC}"
forge test --match-contract EdgeCasesTest -vv
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Edge case tests failed!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 All tests passed successfully!${NC}"
echo ""

echo -e "${BLUE}📊 Generating Test Coverage Report...${NC}"
forge coverage --report lcov
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Coverage report generated!${NC}"
else
    echo -e "${YELLOW}⚠️  Coverage report generation failed (may require additional setup)${NC}"
fi

echo ""
echo -e "${BLUE}📈 Test Statistics:${NC}"
echo "Running comprehensive test statistics..."

# Count total tests
TOTAL_TESTS=$(forge test --list | wc -l)
echo "Total Tests: $TOTAL_TESTS"

# Run gas reporting
echo ""
echo -e "${BLUE}⛽ Gas Usage Report:${NC}"
forge test --gas-report

echo ""
echo -e "${GREEN}🏆 Test Suite Complete!${NC}"
echo ""
echo "Test Categories Completed:"
echo "✅ Unit Tests (PersonaINFT, PersonaStorageManager, PersonaAgentManager)"
echo "✅ Integration Tests (Cross-contract interactions)"
echo "✅ Invariant Tests (Critical system properties)"
echo "✅ Edge Case Tests (Boundary conditions and extreme scenarios)"
echo ""
echo "Your PersonaForge contracts are thoroughly tested and ready for deployment!"
