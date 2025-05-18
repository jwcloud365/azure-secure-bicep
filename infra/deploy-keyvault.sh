#!/bin/bash

# Key Vault parameter values
PREFIX="azuresecure"
ENVIRONMENT="dev"
LOCATION="swedencentral"
SUBNET_ID="/subscriptions/6d505432-f45f-4fb8-9afb-a5c761876cd3/resourceGroups/azuresecure-dev-rg/providers/Microsoft.Network/virtualNetworks/azuresecure-dev-frontend-vnet/subnets/keyvault-subnet"
USER_OBJECT_ID="ed906b0f-4726-43a2-85f6-f16db264fe4f"
SQL_ADMIN="sqlAdmin"
SQL_PASSWORD="P@ssw0rd1234!"

# Deploy Key Vault
echo "Deploying Key Vault..."
az deployment group create \
  --resource-group azuresecure-dev-rg \
  --template-file ./infra/modules/keyVault.bicep \
  --parameters \
    prefix=$PREFIX \
    environment=$ENVIRONMENT \
    location=$LOCATION \
    accessPrincipalObjectId=$USER_OBJECT_ID \
    sqlAdministratorLogin=$SQL_ADMIN \
    sqlAdministratorPassword=$SQL_PASSWORD \
  --name azuresecure-keyvault-deployment

# Note: The subnetId parameter is deliberately omitted as it causes issues in Git Bash
# We will manually set up private endpoints for Key Vault later if needed
