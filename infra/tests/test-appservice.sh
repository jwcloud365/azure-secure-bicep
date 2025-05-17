#!/bin/bash

# Test script for App Service components
# This script validates that the App Service resources have been deployed correctly

# Exit on error
set -e

# Configuration
SUBSCRIPTION_ID="your-subscription-id"
RESOURCE_GROUP="contoso-dev-rg"
APP_SERVICE_PLAN_NAME="contoso-dev-asp"
APP_SERVICE_NAME="contoso-dev-app"

# Login and set subscription
echo "Logging into Azure..."
az account set --subscription $SUBSCRIPTION_ID

echo "Testing App Service components..."

# Test App Service Plan existence
echo "Testing App Service Plan existence..."
APP_SERVICE_PLAN=$(az appservice plan show --resource-group $RESOURCE_GROUP --name $APP_SERVICE_PLAN_NAME)
if [ -z "$APP_SERVICE_PLAN" ]; then
  echo "ERROR: App Service Plan not found!"
  exit 1
fi
echo "App Service Plan exists."

# Verify App Service Plan SKU
SKU=$(echo $APP_SERVICE_PLAN | jq -r '.sku.name')
if [ "$SKU" != "P1v2" ]; then
  echo "ERROR: App Service Plan is not using the expected SKU!"
  exit 1
fi
echo "App Service Plan has the correct SKU."

# Test App Service existence
echo "Testing App Service existence..."
APP_SERVICE=$(az webapp show --resource-group $RESOURCE_GROUP --name $APP_SERVICE_NAME)
if [ -z "$APP_SERVICE" ]; then
  echo "ERROR: App Service not found!"
  exit 1
fi
echo "App Service exists."

# Verify HTTPS Only
HTTPS_ONLY=$(echo $APP_SERVICE | jq -r '.httpsOnly')
if [ "$HTTPS_ONLY" != "true" ]; then
  echo "ERROR: App Service HTTPS Only setting is not enabled!"
  exit 1
fi
echo "App Service HTTPS Only is correctly enabled."

# Verify VNet integration
VNET_INTEGRATION=$(az webapp vnet-integration list --resource-group $RESOURCE_GROUP --name $APP_SERVICE_NAME)
if [ -z "$VNET_INTEGRATION" ]; then
  echo "ERROR: App Service VNet integration not configured!"
  exit 1
fi
echo "App Service VNet integration is configured."

# Verify System-Assigned Managed Identity
IDENTITY_TYPE=$(echo $APP_SERVICE | jq -r '.identity.type')
if [ "$IDENTITY_TYPE" != "SystemAssigned" ]; then
  echo "ERROR: App Service does not have SystemAssigned identity!"
  exit 1
fi
echo "App Service has SystemAssigned identity."

# Check App Settings
echo "Checking App Service settings..."
APP_SETTINGS=$(az webapp config appsettings list --resource-group $RESOURCE_GROUP --name $APP_SERVICE_NAME)
VNET_ROUTE_ALL=$(echo $APP_SETTINGS | jq -r '.[] | select(.name=="WEBSITE_VNET_ROUTE_ALL") | .value')
if [ "$VNET_ROUTE_ALL" != "1" ]; then
  echo "ERROR: WEBSITE_VNET_ROUTE_ALL setting is not enabled!"
  exit 1
fi
echo "WEBSITE_VNET_ROUTE_ALL setting is correctly enabled."

echo "All App Service components have been successfully deployed and validated!"
