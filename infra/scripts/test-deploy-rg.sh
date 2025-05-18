#!/bin/bash

# Test deployment script for the resource group module
# This script tests the deployment of just the resource group module

# Exit on error
set -e

# Configuration
echo "Loading configuration..."
SUBSCRIPTION_ID="6d505432-f45f-4fb8-9afb-a5c761876cd3" 
TENANT_ID="24716ce3-de3f-46ef-a555-0dd2c9e293d8"
LOCATION="eastus"
ENVIRONMENT_NAME="dev"
RESOURCE_NAME_PREFIX="contoso"
TIMESTAMP=$(date +%Y%m%d%H%M%S)
DEPLOYMENT_NAME="rg-test-${TIMESTAMP}"

# Login and set subscription
echo "Logging into Azure..."
az account set --subscription $SUBSCRIPTION_ID

# Deploy just the resource group module
echo "Deploying resource group module..."
az deployment sub create \
  --location $LOCATION \
  --template-file ./infra/modules/resourceGroup.bicep \
  --parameters resourceGroupName="${RESOURCE_NAME_PREFIX}-${ENVIRONMENT_NAME}-rg" location=$LOCATION \
  --name $DEPLOYMENT_NAME

echo "Resource group module deployment completed!"
