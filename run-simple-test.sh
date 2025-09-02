#!/bin/bash

echo "=== Running Simple Test Build Check ==="

# Just try to compile the contracts first
echo "Building contracts..."
forge build

if [ $? -eq 0 ]; then
    echo "✅ Contracts build successfully!"
    
    echo ""
    echo "Running a simple test to verify basic functionality..."
    forge test --match-contract PersonaINFTTest --match-test test_InitialSetup -vv
    
    if [ $? -eq 0 ]; then
        echo "✅ Basic test passed!"
    else
        echo "❌ Basic test failed"
    fi
    
else
    echo "❌ Contracts build failed"
    echo "Some test files have compilation errors that need to be fixed"
fi
