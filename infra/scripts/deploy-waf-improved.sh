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

# Check if resource group exists
if ! az group show --name $RESOURCE_GROUP &> /dev/null; then
    echo "Resource group $RESOURCE_GROUP not found. Creating..."
    az group create --name $RESOURCE_GROUP --location $LOCATION
fi

# 1. Create public IP for WAF if it doesn't exist
echo "Checking for public IP for WAF..."
if ! az network public-ip show --name $WAF_PIP_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
    echo "Creating public IP for WAF..."
    az network public-ip create \
        --resource-group $RESOURCE_GROUP \
        --name $WAF_PIP_NAME \
        --allocation-method Static \
        --sku Standard \
        --location $LOCATION
else
    echo "Public IP $WAF_PIP_NAME already exists."
fi

# 2. Check if Application Gateway already exists
if ! az network application-gateway show --name $WAF_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
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
        --http-listener-protocol Https \
        --routing-rule-type Basic \
        --servers $APP_SERVICE_HOSTNAME \
        --priority 100
        
    if [ $? -ne 0 ]; then
        echo "Error creating Application Gateway. Please check the error message above."
        exit 1
    fi
else
    echo "Application Gateway $WAF_NAME already exists."
fi

# 3. Enable WAF
echo "Enabling WAF with OWASP 3.2 ruleset..."
az network application-gateway waf-config set \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $WAF_NAME \
    --enabled true \
    --firewall-mode Prevention \
    --rule-set-type OWASP \
    --rule-set-version 3.2

# 4. Configure custom health probe
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
    --host-name $APP_SERVICE_HOSTNAME || echo "Health probe creation failed. It may already exist."

# 5. Update HTTP settings with custom probe
echo "Updating HTTP settings to use custom probe..."
az network application-gateway http-settings update \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $WAF_NAME \
    --name appGatewayBackendHttpSettings \
    --probe appServiceHealthProbe || echo "HTTP settings update failed."

# 6. Update HTTP settings with host name from backend address
echo "Setting host name from backend address..."
az network application-gateway http-settings update \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $WAF_NAME \
    --name appGatewayBackendHttpSettings \
    --host-name-from-backend-address true || echo "Host name configuration failed."

# Get the details of deployed WAF
WAF_PUBLIC_IP=$(az network public-ip show \
    --resource-group $RESOURCE_GROUP \
    --name $WAF_PIP_NAME \
    --query ipAddress \
    --output tsv 2>/dev/null || echo "Could not retrieve IP")

echo "======================================"
echo "Application Gateway with WAF deployment completed!"
echo "WAF Public IP: $WAF_PUBLIC_IP"
echo "App Service accessible via: https://$WAF_PUBLIC_IP/"
echo "======================================"
