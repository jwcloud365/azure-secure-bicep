#!/bin/bash

# Full deployment script for Azure infrastructure
# This script deploys the entire infrastructure using Bicep templates

# Script settings
set -e  # Exit on error
set -x  # Echo commands for debugging

# Configuration
echo "Loading configuration..."
SUBSCRIPTION_ID="6d505432-f45f-4fb8-9afb-a5c761876cd3"
TENANT_ID="24716ce3-de3f-46ef-a555-0dd2c9e293d8"
LOCATION="northeurope"
ENVIRONMENT_NAME="dev"
RESOURCE_NAME_PREFIX="contoso"
TIMESTAMP=$(date +%Y%m%d%H%M%S)
DEPLOYMENT_NAME="${RESOURCE_NAME_PREFIX}-${ENVIRONMENT_NAME}-deployment-${TIMESTAMP}"

# Verify files exist
if [ ! -f "./infra/main.bicep" ]; then
    echo "ERROR: main.bicep file not found!"
    exit 1
fi

if [ ! -f "./infra/main.test.parameters.json" ]; then
    echo "ERROR: main.test.parameters.json file not found!"
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

# Deploy full infrastructure
echo "Deploying full infrastructure..."
echo "Using deployment name: $DEPLOYMENT_NAME"

az deployment sub create \
  --location $LOCATION \
  --template-file ./infra/main.bicep \
  --parameters @./infra/main.test.parameters.json \
  --name $DEPLOYMENT_NAME

DEPLOYMENT_STATUS=$?
if [ $DEPLOYMENT_STATUS -eq 0 ]; then
    echo "Full infrastructure deployment completed successfully!"
    echo "Deployment name: $DEPLOYMENT_NAME"
else
    echo "Deployment failed with status: $DEPLOYMENT_STATUS"
    echo "Check the Azure portal for more details."
    exit $DEPLOYMENT_STATUS
fi
