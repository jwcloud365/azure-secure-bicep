#!/bin/bash

# Deployment script for Azure infrastructure
# This script deploys the entire infrastructure using Bicep templates

# Exit on error
set -e

# Configuration
echo "Loading configuration..."
SUBSCRIPTION_ID="your-subscription-id"
TENANT_ID="your-tenant-id"
LOCATION="eastus"
ENVIRONMENT_NAME="dev"
RESOURCE_NAME_PREFIX="contoso"

# Login and set subscription
echo "Logging into Azure..."
az login --tenant $TENANT_ID
az account set --subscription $SUBSCRIPTION_ID

# Deploy infrastructure
echo "Deploying infrastructure..."
az deployment sub create \
  --location $LOCATION \
  --template-file ./infra/main.bicep \
  --parameters ./infra/main.parameters.json \
  --name "${RESOURCE_NAME_PREFIX}-${ENVIRONMENT_NAME}-deployment-$(date +%Y%m%d%H%M%S)"

echo "Deployment completed successfully!"
