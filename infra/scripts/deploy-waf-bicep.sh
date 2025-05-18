#!/bin/bash
# Deploy using bicep template and parameters
# Get the current directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"

echo "Using bicep template at: $INFRA_DIR/modules/waf.bicep"
echo "Using parameters at: $INFRA_DIR/waf.parameters.json"

az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --name $DEPLOYMENT_NAME \
  --template-file "$INFRA_DIR/modules/waf.bicep" \
  --parameters "@$INFRA_DIR/waf.parameters.json" (Application Gateway) deployment script using Bicep
# This script deploys the Application Gateway with WAF enabled using Bicep template

# Configuration variables
RESOURCE_GROUP="azuresecure-dev-rg"
LOCATION="swedencentral"
DEPLOYMENT_NAME="waf-deployment"

echo "=== Deploying Application Gateway with WAF using Bicep ==="

# Deploy using bicep template and parameters
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --name $DEPLOYMENT_NAME \
  --template-file ../modules/waf.bicep \
  --parameters @../waf.parameters.json

echo "Application Gateway with WAF successfully deployed using Bicep!"
