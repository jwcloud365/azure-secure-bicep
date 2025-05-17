#!/bin/bash

# Test deployment script for the networking module
# This script tests the deployment of the networking module

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
DEPLOYMENT_NAME="networking-test-${TIMESTAMP}"
RESOURCE_GROUP="${RESOURCE_NAME_PREFIX}-${ENVIRONMENT_NAME}-rg"

# Login and set subscription
echo "Logging into Azure..."
az account set --subscription $SUBSCRIPTION_ID

# Ensure resource group exists
echo "Checking if resource group exists..."
if ! az group show --name $RESOURCE_GROUP &>/dev/null; then
  echo "Creating resource group $RESOURCE_GROUP..."
  az group create --name $RESOURCE_GROUP --location $LOCATION
else
  echo "Resource group $RESOURCE_GROUP already exists."
fi

# Deploy the networking module
echo "Deploying networking module..."
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file ./infra/modules/networking.bicep \
  --parameters location=$LOCATION prefix=$RESOURCE_NAME_PREFIX environment=$ENVIRONMENT_NAME \
  --name $DEPLOYMENT_NAME \
  --verbose

# List the deployed resources
echo "Listing deployed networking resources..."
echo "Virtual Networks:"
az network vnet list --resource-group $RESOURCE_GROUP --output table

echo "Subnets in Frontend VNet:"
az network vnet subnet list \
  --resource-group $RESOURCE_GROUP \
  --vnet-name "${RESOURCE_NAME_PREFIX}-${ENVIRONMENT_NAME}-frontend-vnet" \
  --output table

echo "Subnets in Backend VNet:"
az network vnet subnet list \
  --resource-group $RESOURCE_GROUP \
  --vnet-name "${RESOURCE_NAME_PREFIX}-${ENVIRONMENT_NAME}-backend-vnet" \
  --output table

echo "Network Security Groups:"
az network nsg list --resource-group $RESOURCE_GROUP --output table

echo "Networking module deployment completed!"
