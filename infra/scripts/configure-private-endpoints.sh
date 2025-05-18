#!/bin/bash

# Private Endpoints Configuration Script
# This script configures private endpoints for Azure SQL and Key Vault

# Configuration variables
RESOURCE_GROUP="azuresecure-dev-rg"
LOCATION="swedencentral"
PREFIX="azuresecure"
ENV="dev"

# SQL Server variables
SQL_SERVER_NAME="${PREFIX}-${ENV}-sqlserver"
SQL_PRIVATE_ENDPOINT_NAME="${PREFIX}-${ENV}-sql-pe"
SQL_VNET_NAME="${PREFIX}-${ENV}-backend-vnet"
SQL_SUBNET_NAME="db-subnet"
SQL_PE_CONNECTION_NAME="${PREFIX}-${ENV}-sql-pe-connection"
SQL_GROUP_ID="sqlServer"

# Key Vault variables
KEY_VAULT_NAME="${PREFIX}-${ENV}-kv"
KV_PRIVATE_ENDPOINT_NAME="${PREFIX}-${ENV}-kv-pe"
KV_VNET_NAME="${PREFIX}-${ENV}-backend-vnet"
KV_SUBNET_NAME="private-endpoints-subnet"
KV_PE_CONNECTION_NAME="${PREFIX}-${ENV}-kv-pe-connection"
KV_GROUP_ID="vault"

echo "=== Configuring Private Endpoints ==="

# Function to get resource ID
get_resource_id() {
    resource_type=$1
    resource_name=$2
    
    az resource show \
        --resource-group $RESOURCE_GROUP \
        --resource-type $resource_type \
        --name $resource_name \
        --query id \
        --output tsv
}

# 1. Configure Private Endpoint for SQL Server
echo "Configuring Private Endpoint for SQL Server..."

# Get SQL Server resource ID
SQL_SERVER_ID=$(get_resource_id "Microsoft.Sql/servers" $SQL_SERVER_NAME)

# Get subnet ID for SQL private endpoint
SQL_SUBNET_ID=$(az network vnet subnet show \
    --resource-group $RESOURCE_GROUP \
    --vnet-name $SQL_VNET_NAME \
    --name $SQL_SUBNET_NAME \
    --query id \
    --output tsv)

# Create private endpoint for SQL Server
if ! az network private-endpoint show --name $SQL_PRIVATE_ENDPOINT_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
    echo "Creating private endpoint for SQL Server..."
    az network private-endpoint create \
        --name $SQL_PRIVATE_ENDPOINT_NAME \
        --resource-group $RESOURCE_GROUP \
        --location $LOCATION \
        --subnet $SQL_SUBNET_ID \
        --private-connection-resource-id $SQL_SERVER_ID \
        --group-id $SQL_GROUP_ID \
        --connection-name $SQL_PE_CONNECTION_NAME
else
    echo "SQL Server private endpoint already exists."
fi

# 2. Configure Private Endpoint for Key Vault
echo "Configuring Private Endpoint for Key Vault..."

# Get Key Vault resource ID
KEY_VAULT_ID=$(get_resource_id "Microsoft.KeyVault/vaults" $KEY_VAULT_NAME)

# Get subnet ID for Key Vault private endpoint
KV_SUBNET_ID=$(az network vnet subnet show \
    --resource-group $RESOURCE_GROUP \
    --vnet-name $KV_VNET_NAME \
    --name $KV_SUBNET_NAME \
    --query id \
    --output tsv)

# Create private endpoint for Key Vault
if ! az network private-endpoint show --name $KV_PRIVATE_ENDPOINT_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
    echo "Creating private endpoint for Key Vault..."
    az network private-endpoint create \
        --name $KV_PRIVATE_ENDPOINT_NAME \
        --resource-group $RESOURCE_GROUP \
        --location $LOCATION \
        --subnet $KV_SUBNET_ID \
        --private-connection-resource-id $KEY_VAULT_ID \
        --group-id $KV_GROUP_ID \
        --connection-name $KV_PE_CONNECTION_NAME
else
    echo "Key Vault private endpoint already exists."
fi

# 3. Update Key Vault network settings to disable public access
echo "Updating Key Vault network settings..."
az keyvault update \
    --name $KEY_VAULT_NAME \
    --resource-group $RESOURCE_GROUP \
    --default-action Deny

echo "Private Endpoints configuration completed!"
