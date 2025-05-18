#!/bin/bash

# Monitoring Deployment Script
# This script deploys Log Analytics Workspace and configures diagnostics settings

# Configuration variables
RESOURCE_GROUP="azuresecure-dev-rg"
LOCATION="swedencentral"
PREFIX="azuresecure"
ENV="dev"

# Monitoring resources
LAW_NAME="${PREFIX}-${ENV}-law"
APP_INSIGHTS_NAME="${PREFIX}-${ENV}-appinsights"

# Resources to configure diagnostics for
APP_NAME="${PREFIX}-${ENV}-app"
SQL_SERVER_NAME="${PREFIX}-${ENV}-sqlserver"
WAF_NAME="${PREFIX}-${ENV}-waf"
KEY_VAULT_NAME="${PREFIX}-${ENV}-kv"

echo "=== Deploying Monitoring Resources ==="

# 1. Create Log Analytics Workspace if it doesn't exist
echo "Checking for Log Analytics Workspace..."
if ! az monitor log-analytics workspace show --resource-group $RESOURCE_GROUP --workspace-name $LAW_NAME &> /dev/null; then
    echo "Creating Log Analytics Workspace..."
    az monitor log-analytics workspace create \
        --resource-group $RESOURCE_GROUP \
        --workspace-name $LAW_NAME \
        --location $LOCATION \
        --sku PerGB2018
else
    echo "Log Analytics Workspace already exists."
fi

# 2. Create Application Insights if it doesn't exist
echo "Checking for Application Insights..."
if ! az monitor app-insights component show --resource-group $RESOURCE_GROUP --app $APP_INSIGHTS_NAME &> /dev/null; then
    echo "Creating Application Insights..."
    az monitor app-insights component create \
        --resource-group $RESOURCE_GROUP \
        --app $APP_INSIGHTS_NAME \
        --location $LOCATION \
        --application-type web \
        --workspace $LAW_NAME
else
    echo "Application Insights already exists."
fi

# Get Log Analytics Workspace ID
LAW_ID=$(az monitor log-analytics workspace show \
    --resource-group $RESOURCE_GROUP \
    --workspace-name $LAW_NAME \
    --query id \
    --output tsv)

# 3. Configure diagnostic settings for App Service
echo "Configuring diagnostic settings for App Service..."
APP_ID=$(az webapp show \
    --resource-group $RESOURCE_GROUP \
    --name $APP_NAME \
    --query id \
    --output tsv)

az monitor diagnostic-settings create \
    --resource $APP_ID \
    --name "${APP_NAME}-diagnostics" \
    --workspace $LAW_ID \
    --logs '[{"category": "AppServiceHTTPLogs", "enabled": true}, {"category": "AppServiceConsoleLogs", "enabled": true}, {"category": "AppServiceAppLogs", "enabled": true}]' \
    --metrics '[{"category": "AllMetrics", "enabled": true}]'

# 4. Configure diagnostic settings for SQL Server
echo "Configuring diagnostic settings for SQL Server..."
SQL_ID=$(az sql server show \
    --resource-group $RESOURCE_GROUP \
    --name $SQL_SERVER_NAME \
    --query id \
    --output tsv)

az monitor diagnostic-settings create \
    --resource $SQL_ID \
    --name "${SQL_SERVER_NAME}-diagnostics" \
    --workspace $LAW_ID \
    --logs '[{"category": "SQLSecurityAuditEvents", "enabled": true}, {"category": "DevOpsOperationsAudit", "enabled": true}]'

# 5. Configure diagnostic settings for Key Vault
echo "Configuring diagnostic settings for Key Vault..."
KV_ID=$(az keyvault show \
    --resource-group $RESOURCE_GROUP \
    --name $KEY_VAULT_NAME \
    --query id \
    --output tsv)

az monitor diagnostic-settings create \
    --resource $KV_ID \
    --name "${KEY_VAULT_NAME}-diagnostics" \
    --workspace $LAW_ID \
    --logs '[{"category": "AuditEvent", "enabled": true}, {"category": "AzurePolicyEvaluationDetails", "enabled": true}]' \
    --metrics '[{"category": "AllMetrics", "enabled": true}]'

# 6. Configure diagnostic settings for WAF (Application Gateway)
echo "Configuring diagnostic settings for Application Gateway..."
WAF_ID=$(az network application-gateway show \
    --resource-group $RESOURCE_GROUP \
    --name $WAF_NAME \
    --query id \
    --output tsv)

az monitor diagnostic-settings create \
    --resource $WAF_ID \
    --name "${WAF_NAME}-diagnostics" \
    --workspace $LAW_ID \
    --logs '[{"category": "ApplicationGatewayAccessLog", "enabled": true}, {"category": "ApplicationGatewayPerformanceLog", "enabled": true}, {"category": "ApplicationGatewayFirewallLog", "enabled": true}]' \
    --metrics '[{"category": "AllMetrics", "enabled": true}]'

echo "Monitoring configuration completed!"
