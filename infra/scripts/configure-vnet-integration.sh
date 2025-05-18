#!/bin/bash

# VNet Integration Configuration Script
# This script configures VNet integration for App Service

# Configuration variables
RESOURCE_GROUP="azuresecure-dev-rg"
PREFIX="azuresecure"
ENV="dev"

# App Service variables
APP_NAME="${PREFIX}-${ENV}-app"
VNET_NAME="${PREFIX}-${ENV}-frontend-vnet"
SUBNET_NAME="app-service-subnet"

echo "=== Configuring VNet Integration for App Service ==="

# Get the subnet ID
SUBNET_ID=$(az network vnet subnet show \
    --resource-group $RESOURCE_GROUP \
    --vnet-name $VNET_NAME \
    --name $SUBNET_NAME \
    --query id \
    --output tsv)

# Configure VNet integration
echo "Adding VNet integration to App Service..."
az webapp vnet-integration add \
    --resource-group $RESOURCE_GROUP \
    --name $APP_NAME \
    --vnet $VNET_NAME \
    --subnet $SUBNET_NAME

# Enable WEBSITE_DNS_SERVER and WEBSITE_VNET_ROUTE_ALL settings for proper DNS resolution
echo "Configuring App Service settings for VNet integration..."
az webapp config appsettings set \
    --resource-group $RESOURCE_GROUP \
    --name $APP_NAME \
    --settings WEBSITE_DNS_SERVER=168.63.129.16 WEBSITE_VNET_ROUTE_ALL=1

echo "App Service VNet integration completed!"
