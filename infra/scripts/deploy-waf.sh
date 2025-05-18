#!/bin/bash

# WAF (Application Gateway) deployment script
# This script deploys a simplified version of the Application Gateway with WAF enabled

# Configuration variables
RESOURCE_GROUP="azuresecure-dev-rg"
LOCATION="swedencentral"
PREFIX="azuresecure"
ENV="dev"
APP_SERVICE_HOSTNAME="azuresecure-dev-app.azurewebsites.net"

# WAF resources
WAF_NAME="${PREFIX}-${ENV}-waf"
WAF_PIP_NAME="${PREFIX}-${ENV}-waf-pip"
VNET_NAME="${PREFIX}-${ENV}-frontend-vnet"
WAF_SUBNET="waf-subnet"

echo "=== Deploying Application Gateway with WAF ==="

# 1. Create public IP for WAF
echo "Creating public IP for WAF..."
az network public-ip create \
  --resource-group $RESOURCE_GROUP \
  --name $WAF_PIP_NAME \
  --allocation-method Static \
  --sku Standard \
  --location $LOCATION

# 2. Create Application Gateway with WAF
echo "Creating Application Gateway with WAF..."
az network application-gateway create \
  --resource-group $RESOURCE_GROUP \
  --name $WAF_NAME \
  --location $LOCATION \
  --vnet-name $VNET_NAME \
  --subnet $WAF_SUBNET \
  --public-ip-address $WAF_PIP_NAME \
  --sku WAF_v2 \
  --capacity 2 \
  --http-settings-cookie-based-affinity Disabled \
  --http-settings-port 443 \
  --http-settings-protocol Https \
  --frontend-port 443 \
  --frontend-port-name frontendPort \
  --http-listener-protocol Https \
  --routing-rule-type Basic \
  --servers $APP_SERVICE_HOSTNAME

# 3. Configure HTTP settings with the host name
echo "Configuring HTTP settings with host name..."
az network application-gateway http-settings update \
  --resource-group $RESOURCE_GROUP \
  --gateway-name $WAF_NAME \
  --name appGatewayBackendHttpSettings \
  --host-name $APP_SERVICE_HOSTNAME

# 4. Enable WAF
echo "Enabling WAF with OWASP 3.2 ruleset..."
az network application-gateway waf-config set \
  --resource-group $RESOURCE_GROUP \
  --gateway-name $WAF_NAME \
  --enabled true \
  --firewall-mode Prevention \
  --rule-set-type OWASP \
  --rule-set-version 3.2

# 5. Configure custom health probe
echo "Configuring custom health probe..."
az network application-gateway probe create \
  --resource-group $RESOURCE_GROUP \
  --gateway-name $WAF_NAME \
  --name appServiceHealthProbe \
  --path "/api/health" \
  --interval 30 \
  --timeout 30 \
  --threshold 3 \
  --protocol Https \
  --host www.contoso.com

# 6. Update HTTP settings with custom probe
echo "Updating HTTP settings to use custom probe..."
az network application-gateway http-settings update \
  --resource-group $RESOURCE_GROUP \
  --gateway-name $WAF_NAME \
  --name appGatewayBackendHttpSettings \
  --probe appServiceHealthProbe

echo "Application Gateway with WAF successfully deployed!"
