#!/bin/bash

# Master test script for Azure infrastructure
# This script runs all component test scripts in sequence

# Exit on error
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo "Starting infrastructure validation tests..."

# Run component tests
echo "Running networking tests..."
bash "$SCRIPT_DIR/test-networking.sh"
echo "Networking tests completed."

echo "Running database tests..."
bash "$SCRIPT_DIR/test-database.sh"
echo "Database tests completed."

echo "Running App Service tests..."
bash "$SCRIPT_DIR/test-appservice.sh"
echo "App Service tests completed."

echo "Running WAF tests..."
bash "$SCRIPT_DIR/test-waf.sh"
echo "WAF tests completed."

echo "Running monitoring tests..."
bash "$SCRIPT_DIR/test-monitoring.sh"
echo "Monitoring tests completed."

echo "All infrastructure validation tests have completed successfully!"
