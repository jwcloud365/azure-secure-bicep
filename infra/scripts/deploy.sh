#!/bin/bash

# Deployment script for Azure infrastructure
# This script deploys the entire infrastructure using Bicep templates

# Exit on error
set -e

# Configuration
echo "Loading configuration..."
SUBSCRIPTION_ID="6d505432-f45f-4fb8-9afb-a5c761876cd3"
TENANT_ID="24716ce3-de3f-46ef-a555-0dd2c9e293d8"
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
