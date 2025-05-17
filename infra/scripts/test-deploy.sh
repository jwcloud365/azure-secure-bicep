#!/bin/bash

# Test deployment script for Azure infrastructure
# This script deploys just the resource group for testing purposes

# Exit on error
set -e

# Configuration
echo "Loading configuration..."
SUBSCRIPTION_ID="6d505432-f45f-4fb8-9afb-a5c761876cd3"
TENANT_ID="24716ce3-de3f-46ef-a555-0dd2c9e293d8"
LOCATION="eastus"
TIMESTAMP=$(date +%Y%m%d%H%M%S)

# Login and set subscription
echo "Logging into Azure..."
az login --tenant $TENANT_ID
az account set --subscription $SUBSCRIPTION_ID

# Create resource group only for testing
echo "Creating resource group for testing..."
RESOURCE_GROUP="contoso-dev-rg-test"
az group create --name $RESOURCE_GROUP --location $LOCATION --output json

# List the resource group to confirm creation
echo "Listing resource group to confirm creation:"
az group show --name $RESOURCE_GROUP --output table

echo "Resource group created successfully!"
echo "You can now test resource deployments to this resource group."
