#!/bin/bash

# Test script for networking components
# This script validates that the networking resources have been deployed correctly

# Exit on error
set -e

# Configuration
SUBSCRIPTION_ID="your-subscription-id"
RESOURCE_GROUP="contoso-dev-rg"
FRONTEND_VNET_NAME="contoso-dev-frontend-vnet"
BACKEND_VNET_NAME="contoso-dev-backend-vnet"
WAF_SUBNET_NAME="waf-subnet"
APP_SERVICE_SUBNET_NAME="appservice-subnet"
DATABASE_SUBNET_NAME="database-subnet"

# Login and set subscription
echo "Logging into Azure..."
az account set --subscription $SUBSCRIPTION_ID

echo "Testing networking components..."

# Test VNet existence
echo "Testing VNet existence..."
FRONTEND_VNET=$(az network vnet show --resource-group $RESOURCE_GROUP --name $FRONTEND_VNET_NAME)
if [ -z "$FRONTEND_VNET" ]; then
  echo "ERROR: Frontend VNet not found!"
  exit 1
fi
echo "Frontend VNet exists."

BACKEND_VNET=$(az network vnet show --resource-group $RESOURCE_GROUP --name $BACKEND_VNET_NAME)
if [ -z "$BACKEND_VNET" ]; then
  echo "ERROR: Backend VNet not found!"
  exit 1
fi
echo "Backend VNet exists."

# Test subnet existence
echo "Testing subnet existence..."
WAF_SUBNET=$(az network vnet subnet show --resource-group $RESOURCE_GROUP --vnet-name $FRONTEND_VNET_NAME --name $WAF_SUBNET_NAME)
if [ -z "$WAF_SUBNET" ]; then
  echo "ERROR: WAF subnet not found!"
  exit 1
fi
echo "WAF subnet exists."

APP_SERVICE_SUBNET=$(az network vnet subnet show --resource-group $RESOURCE_GROUP --vnet-name $FRONTEND_VNET_NAME --name $APP_SERVICE_SUBNET_NAME)
if [ -z "$APP_SERVICE_SUBNET" ]; then
  echo "ERROR: App Service subnet not found!"
  exit 1
fi
echo "App Service subnet exists."

DATABASE_SUBNET=$(az network vnet subnet show --resource-group $RESOURCE_GROUP --vnet-name $BACKEND_VNET_NAME --name $DATABASE_SUBNET_NAME)
if [ -z "$DATABASE_SUBNET" ]; then
  echo "ERROR: Database subnet not found!"
  exit 1
fi
echo "Database subnet exists."

# Test VNet peering
echo "Testing VNet peering..."
FRONTEND_TO_BACKEND_PEERING=$(az network vnet peering show --resource-group $RESOURCE_GROUP --vnet-name $FRONTEND_VNET_NAME --name "${FRONTEND_VNET_NAME}-to-${BACKEND_VNET_NAME}")
if [ -z "$FRONTEND_TO_BACKEND_PEERING" ]; then
  echo "ERROR: Frontend to Backend VNet peering not found!"
  exit 1
fi
echo "Frontend to Backend VNet peering exists."

BACKEND_TO_FRONTEND_PEERING=$(az network vnet peering show --resource-group $RESOURCE_GROUP --vnet-name $BACKEND_VNET_NAME --name "${BACKEND_VNET_NAME}-to-${FRONTEND_VNET_NAME}")
if [ -z "$BACKEND_TO_FRONTEND_PEERING" ]; then
  echo "ERROR: Backend to Frontend VNet peering not found!"
  exit 1
fi
echo "Backend to Frontend VNet peering exists."

# Test Private DNS Zone
echo "Testing Private DNS Zone..."
SQL_PRIVATE_DNS_ZONE=$(az network private-dns zone show --resource-group $RESOURCE_GROUP --name "privatelink.database.windows.net")
if [ -z "$SQL_PRIVATE_DNS_ZONE" ]; then
  echo "ERROR: SQL Private DNS Zone not found!"
  exit 1
fi
echo "SQL Private DNS Zone exists."

echo "All networking components have been successfully deployed and validated!"
