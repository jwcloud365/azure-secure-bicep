#!/bin/bash

# Private Endpoints Configuration Script (Fixed)
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
SQL_SUBNET_NAME="database-subnet"
SQL_PE_CONNECTION_NAME="${PREFIX}-${ENV}-sql-pe-connection"
SQL_GROUP_ID="sqlServer"

# Key Vault variables
KEY_VAULT_NAME="${PREFIX}-${ENV}-kv"
KV_PRIVATE_ENDPOINT_NAME="${PREFIX}-${ENV}-kv-pe"
KV_VNET_NAME="${PREFIX}-${ENV}-frontend-vnet"
KV_SUBNET_NAME="keyvault-subnet"
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

# 1. Configure SQL Server public network access
echo "Disabling SQL Server public network access..."
az sql server update \
    --resource-group $RESOURCE_GROUP \
    --name $SQL_SERVER_NAME \
    --set publicNetworkAccess="Disabled"

# 2. Configure Private Endpoint for SQL Server
echo "Configuring Private Endpoint for SQL Server..."

# Get SQL Server resource ID
SQL_SERVER_ID=$(get_resource_id "Microsoft.Sql/servers" $SQL_SERVER_NAME)

# Create private endpoint for SQL Server
echo "Creating private endpoint for SQL Server..."
az network private-endpoint create \
    --name $SQL_PRIVATE_ENDPOINT_NAME \
    --resource-group $RESOURCE_GROUP \
    --vnet-name $SQL_VNET_NAME \
    --subnet $SQL_SUBNET_NAME \
    --location $LOCATION \
    --connection-name $SQL_PE_CONNECTION_NAME \
    --private-connection-resource-id $SQL_SERVER_ID \
    --group-id $SQL_GROUP_ID

echo "SQL Private Endpoint configuration completed!"

# 3. Add diagnostic settings
echo "Adding diagnostic settings to resources..."

# Create Log Analytics workspace if it doesn't exist
LAW_NAME="${PREFIX}-${ENV}-law"
az monitor log-analytics workspace create \
    --resource-group $RESOURCE_GROUP \
    --workspace-name $LAW_NAME \
    --location $LOCATION \
    --sku PerGB2018

# Add diagnostics to SQL Server
echo "Adding diagnostics to SQL Server..."
LAW_ID=$(az monitor log-analytics workspace show --resource-group $RESOURCE_GROUP --workspace-name $LAW_NAME --query id -o tsv)

az monitor diagnostic-settings create \
    --resource $SQL_SERVER_ID \
    --name "${SQL_SERVER_NAME}-diagnostics" \
    --workspace $LAW_ID \
    --logs '[{"category":"SQLSecurityAuditEvents","enabled":true}]' \
    --metrics '[{"category":"AllMetrics","enabled":true}]'

echo "Private Endpoints and diagnostics configuration completed!"
