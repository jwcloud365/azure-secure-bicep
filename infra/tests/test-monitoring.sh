#!/bin/bash

# Test script for monitoring components
# This script validates that the monitoring resources have been deployed correctly

# Exit on error
set -e

# Configuration
SUBSCRIPTION_ID="your-subscription-id"
RESOURCE_GROUP="contoso-dev-rg"
LOG_ANALYTICS_WORKSPACE_NAME="contoso-dev-law"
APP_INSIGHTS_NAME="contoso-dev-ai"

# Login and set subscription
echo "Logging into Azure..."
az account set --subscription $SUBSCRIPTION_ID

echo "Testing monitoring components..."

# Test Log Analytics Workspace existence
echo "Testing Log Analytics Workspace existence..."
LOG_ANALYTICS_WORKSPACE=$(az monitor log-analytics workspace show --resource-group $RESOURCE_GROUP --workspace-name $LOG_ANALYTICS_WORKSPACE_NAME)
if [ -z "$LOG_ANALYTICS_WORKSPACE" ]; then
  echo "ERROR: Log Analytics Workspace not found!"
  exit 1
fi
echo "Log Analytics Workspace exists."

# Verify Log Analytics SKU
SKU=$(echo $LOG_ANALYTICS_WORKSPACE | jq -r '.sku.name')
if [ "$SKU" != "PerGB2018" ]; then
  echo "ERROR: Log Analytics Workspace is not using the expected SKU!"
  exit 1
fi
echo "Log Analytics Workspace has the correct SKU."

# Test Application Insights existence
echo "Testing Application Insights existence..."
APP_INSIGHTS=$(az monitor app-insights component show --resource-group $RESOURCE_GROUP --app $APP_INSIGHTS_NAME)
if [ -z "$APP_INSIGHTS" ]; then
  echo "ERROR: Application Insights not found!"
  exit 1
fi
echo "Application Insights exists."

# Verify Application Insights kind
KIND=$(echo $APP_INSIGHTS | jq -r '.kind')
if [ "$KIND" != "web" ]; then
  echo "ERROR: Application Insights is not of 'web' kind!"
  exit 1
fi
echo "Application Insights has the correct kind."

# Verify Application Insights linked to Log Analytics
WORKSPACE_ID=$(echo $APP_INSIGHTS | jq -r '.workspaceResourceId')
if [ -z "$WORKSPACE_ID" ] || [[ "$WORKSPACE_ID" != *"$LOG_ANALYTICS_WORKSPACE_NAME"* ]]; then
  echo "ERROR: Application Insights is not linked to the expected Log Analytics Workspace!"
  exit 1
fi
echo "Application Insights is correctly linked to Log Analytics Workspace."

# Test diagnostic settings for App Service
echo "Testing diagnostic settings for App Service..."
APP_SERVICE_DIAG=$(az monitor diagnostic-settings list --resource "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Web/sites/contoso-dev-app")
if [ -z "$APP_SERVICE_DIAG" ] || [ "$APP_SERVICE_DIAG" == "[]" ]; then
  echo "ERROR: No diagnostic settings found for App Service!"
  exit 1
fi
echo "Diagnostic settings for App Service exist."

# Test diagnostic settings for SQL Server
echo "Testing diagnostic settings for SQL Server..."
SQL_SERVER_DIAG=$(az monitor diagnostic-settings list --resource "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Sql/servers/contoso-dev-sqlserver")
if [ -z "$SQL_SERVER_DIAG" ] || [ "$SQL_SERVER_DIAG" == "[]" ]; then
  echo "ERROR: No diagnostic settings found for SQL Server!"
  exit 1
fi
echo "Diagnostic settings for SQL Server exist."

# Test diagnostic settings for WAF
echo "Testing diagnostic settings for WAF..."
WAF_DIAG=$(az monitor diagnostic-settings list --resource "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/applicationGateways/contoso-dev-waf")
if [ -z "$WAF_DIAG" ] || [ "$WAF_DIAG" == "[]" ]; then
  echo "ERROR: No diagnostic settings found for WAF!"
  exit 1
fi
echo "Diagnostic settings for WAF exist."

echo "All monitoring components have been successfully deployed and validated!"
