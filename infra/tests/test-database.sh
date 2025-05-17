#!/bin/bash

# Test script for database components
# This script validates that the database resources have been deployed correctly

# Exit on error
set -e

# Configuration
SUBSCRIPTION_ID="your-subscription-id"
RESOURCE_GROUP="contoso-dev-rg"
SQL_SERVER_NAME="contoso-dev-sqlserver"
SQL_DATABASE_NAME="contoso-dev-sqldb"
SQL_PE_NAME="${SQL_SERVER_NAME}-pe"

# Login and set subscription
echo "Logging into Azure..."
az account set --subscription $SUBSCRIPTION_ID

echo "Testing database components..."

# Test SQL Server existence
echo "Testing SQL Server existence..."
SQL_SERVER=$(az sql server show --resource-group $RESOURCE_GROUP --name $SQL_SERVER_NAME)
if [ -z "$SQL_SERVER" ]; then
  echo "ERROR: SQL Server not found!"
  exit 1
fi
echo "SQL Server exists."

# Verify public network access is disabled
PUBLIC_NETWORK_ACCESS=$(echo $SQL_SERVER | jq -r '.publicNetworkAccess')
if [ "$PUBLIC_NETWORK_ACCESS" != "Disabled" ]; then
  echo "ERROR: SQL Server public network access is not disabled!"
  exit 1
fi
echo "SQL Server public network access is correctly disabled."

# Test SQL Database existence
echo "Testing SQL Database existence..."
SQL_DATABASE=$(az sql db show --resource-group $RESOURCE_GROUP --server $SQL_SERVER_NAME --name $SQL_DATABASE_NAME)
if [ -z "$SQL_DATABASE" ]; then
  echo "ERROR: SQL Database not found!"
  exit 1
fi
echo "SQL Database exists."

# Test Private Endpoint existence
echo "Testing Private Endpoint existence..."
PRIVATE_ENDPOINT=$(az network private-endpoint show --resource-group $RESOURCE_GROUP --name $SQL_PE_NAME)
if [ -z "$PRIVATE_ENDPOINT" ]; then
  echo "ERROR: Private Endpoint not found!"
  exit 1
fi
echo "Private Endpoint exists."

# Verify private endpoint connection
CONNECTION_STATUS=$(az network private-endpoint-connection list --resource-group $RESOURCE_GROUP --name $SQL_SERVER_NAME --type Microsoft.Sql/servers | jq -r '.[0].properties.privateLinkServiceConnectionState.status')
if [ "$CONNECTION_STATUS" != "Approved" ]; then
  echo "ERROR: Private Endpoint connection not approved!"
  exit 1
fi
echo "Private Endpoint connection is approved."

echo "All database components have been successfully deployed and validated!"
