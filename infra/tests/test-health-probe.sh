#!/bin/bash

# Health Probe Test Script
# This script validates the health probe configuration for Application Gateway

# Configuration
SUBSCRIPTION_ID="6d505432-f45f-4fb8-9afb-a5c761876cd3"
TENANT_ID="24716ce3-de3f-46ef-a555-0dd2c9e293d8"
RESOURCE_GROUP="contoso-dev-rg"
WAF_NAME="contoso-dev-waf"

# Login to Azure
echo "=== Logging into Azure ==="
az login --tenant $TENANT_ID
az account set --subscription $SUBSCRIPTION_ID
az account show

# Check WAF health probe configuration
echo "=== Checking Application Gateway Health Probe Configuration ==="
WAF_INFO=$(az network application-gateway show \
  --name $WAF_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "probes[?name=='appServiceHealthProbe']" -o json)

echo "Health Probe Configuration:"
echo $WAF_INFO | jq .

# Output health probe details in a readable format
HEALTH_PROBE_PATH=$(echo $WAF_INFO | jq -r ".[0].path")
HEALTH_PROBE_PROTOCOL=$(echo $WAF_INFO | jq -r ".[0].protocol")
HEALTH_PROBE_INTERVAL=$(echo $WAF_INFO | jq -r ".[0].interval")
HEALTH_PROBE_TIMEOUT=$(echo $WAF_INFO | jq -r ".[0].timeout")
HEALTH_PROBE_UNHEALTHY_THRESHOLD=$(echo $WAF_INFO | jq -r ".[0].unhealthyThreshold")
HEALTH_PROBE_PICK_HOST_NAME=$(echo $WAF_INFO | jq -r ".[0].pickHostNameFromBackendHttpSettings")
HEALTH_PROBE_MIN_SERVERS=$(echo $WAF_INFO | jq -r ".[0].minServers")
HEALTH_PROBE_STATUS_CODES=$(echo $WAF_INFO | jq -r ".[0].match.statusCodes | join(\",\")")

echo "===================================="
echo "Health Probe Path: $HEALTH_PROBE_PATH"
echo "Health Probe Protocol: $HEALTH_PROBE_PROTOCOL"
echo "Health Probe Interval: $HEALTH_PROBE_INTERVAL seconds"
echo "Health Probe Timeout: $HEALTH_PROBE_TIMEOUT seconds"
echo "Health Probe Unhealthy Threshold: $HEALTH_PROBE_UNHEALTHY_THRESHOLD"
echo "Health Probe Pick Host Name: $HEALTH_PROBE_PICK_HOST_NAME"
echo "Health Probe Min Servers: $HEALTH_PROBE_MIN_SERVERS"
echo "Health Probe Status Codes: $HEALTH_PROBE_STATUS_CODES"
echo "===================================="

# Check App Service health endpoint
echo "=== Getting App Service URL ==="
APP_SERVICE_NAME="contoso-dev-app"
APP_SERVICE_URL=$(az webapp show \
  --name $APP_SERVICE_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "defaultHostName" -o tsv)

echo "App Service URL: $APP_SERVICE_URL"

echo "=== Checking App Service Health Endpoint ==="
HEALTH_URL="https://$APP_SERVICE_URL$HEALTH_PROBE_PATH"
echo "Testing health endpoint: $HEALTH_URL"

# We'll need to create a sample health endpoint for testing
# For now, we'll just show the command to check it
echo "To test the health endpoint, run: curl -v $HEALTH_URL"

echo "=== Health Probe Test Complete ==="
