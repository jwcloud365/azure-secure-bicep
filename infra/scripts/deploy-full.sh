#!/bin/bash

# Full deployment script for Azure infrastructure
# This script deploys the entire secure Azure infrastructure

# Script settings
set -e  # Exit on error

# Configuration
echo "Loading configuration..."
SUBSCRIPTION_ID="6d505432-f45f-4fb8-9afb-a5c761876cd3"
TENANT_ID="24716ce3-de3f-46ef-a555-0dd2c9e293d8"
LOCATION="swedencentral"
ENVIRONMENT_NAME="dev"
RESOURCE_NAME_PREFIX="azuresecure"
TIMESTAMP=$(date +%Y%m%d%H%M%S)
DEPLOYMENT_NAME="${RESOURCE_NAME_PREFIX}-${ENVIRONMENT_NAME}-deployment-${TIMESTAMP}"

# Get script directory for relative paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"

# Verify required parameter files exist
if [ ! -f "$INFRA_DIR/main.deployment.parameters.json" ]; then
    echo "ERROR: main.deployment.parameters.json file not found!"
    exit 1
fi

if [ ! -f "$INFRA_DIR/keyvault.parameters.json" ]; then
    echo "ERROR: keyvault.parameters.json file not found!"
    exit 1
fi

if [ ! -f "$INFRA_DIR/database.parameters.json" ]; then
    echo "ERROR: database.parameters.json file not found!"
    exit 1
fi

if [ ! -f "$INFRA_DIR/appservice.parameters.json" ]; then
    echo "ERROR: appservice.parameters.json file not found!"
    exit 1
fi

# Login and set subscription
echo "Logging into Azure..."
az login --tenant $TENANT_ID
az account set --subscription $SUBSCRIPTION_ID
az account show

# Verify Azure CLI is logged in and using correct subscription
SUB_CHECK=$(az account show --query "id" -o tsv)
if [ "$SUB_CHECK" != "$SUBSCRIPTION_ID" ]; then
    echo "ERROR: Not logged into the correct subscription!"
    echo "Expected: $SUBSCRIPTION_ID"
    echo "Actual: $SUB_CHECK"
    exit 1
fi

# Deploy full infrastructure in stages
echo "=== Starting Full Infrastructure Deployment ==="
echo "Using deployment name: $DEPLOYMENT_NAME"
echo "Script directory: $SCRIPT_DIR"
echo "Infrastructure directory: $INFRA_DIR"

# Function to show progress
show_progress() {
    echo "---------------------------------------------"
    echo "✓ $1 COMPLETED"
    echo "---------------------------------------------"
    echo
}

# 1. Deploy Resource Group
echo "Step 1/10: Deploying Resource Group"
bash "$SCRIPT_DIR/test-deploy-rg.sh"
show_progress "RESOURCE GROUP DEPLOYMENT"

# 2. Deploy Networking
echo "Step 2/10: Deploying Networking Infrastructure"
bash "$SCRIPT_DIR/test-deploy-networking.sh"
show_progress "NETWORKING INFRASTRUCTURE DEPLOYMENT"

# 3. Deploy Key Vault
echo "Step 3/10: Deploying Key Vault"
bash "$SCRIPT_DIR/deploy-keyvault.sh"
show_progress "KEY VAULT DEPLOYMENT"

# 4. Deploy Database
echo "Step 4/10: Deploying SQL Database"
az deployment group create \
  --resource-group azuresecure-dev-rg \
  --template-file "$INFRA_DIR/modules/database-simple.bicep" \
  --parameters @"$INFRA_DIR/database.parameters.json"
show_progress "DATABASE DEPLOYMENT"

# 5. Deploy App Service
echo "Step 5/10: Deploying App Service"
az deployment group create \
  --resource-group azuresecure-dev-rg \
  --template-file "$INFRA_DIR/modules/appService-simple.bicep" \
  --parameters @"$INFRA_DIR/appservice.parameters.json"
show_progress "APP SERVICE DEPLOYMENT"

# 6. Deploy WAF (Application Gateway)
echo "Step 6/10: Deploying WAF (Application Gateway)"
bash "$SCRIPT_DIR/deploy-waf-improved.sh"
show_progress "WAF DEPLOYMENT"

# 7. Configure VNet Integration
echo "Step 7/10: Configuring VNet Integration for App Service"
bash "$SCRIPT_DIR/configure-vnet-integration.sh"
show_progress "VNET INTEGRATION CONFIGURATION"

# 8. Configure Private Endpoints
echo "Step 8/10: Configuring Private Endpoints"
bash "$SCRIPT_DIR/configure-private-endpoints.sh"
show_progress "PRIVATE ENDPOINTS CONFIGURATION"

# 9. Deploy Monitoring
echo "Step 9/10: Deploying Monitoring Resources"
bash "$SCRIPT_DIR/deploy-monitoring.sh"
show_progress "MONITORING DEPLOYMENT"

# 10. Validate Infrastructure
echo "Step 10/10: Validating Infrastructure"
bash "$SCRIPT_DIR/validate-infrastructure.sh"

echo
echo "=== FULL INFRASTRUCTURE DEPLOYMENT COMPLETED SUCCESSFULLY ==="
echo "Deployment name: $DEPLOYMENT_NAME"
echo "Date and time: $(date)"
