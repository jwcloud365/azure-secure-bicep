#!/bin/bash

# Deployment Validation Script
# This script validates that all infrastructure components are properly deployed and connected

# Configuration
SUBSCRIPTION_ID="6d505432-f45f-4fb8-9afb-a5c761876cd3"
TENANT_ID="24716ce3-de3f-46ef-a555-0dd2c9e293d8"
RESOURCE_GROUP="contoso-dev-rg"
ENVIRONMENT_NAME="dev"
RESOURCE_PREFIX="contoso"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Login to Azure
echo "=== Logging into Azure ==="
az login --tenant $TENANT_ID
az account set --subscription $SUBSCRIPTION_ID
az account show

# Function to check resources
check_resource() {
    resource_type=$1
    resource_name=$2
    description=$3

    echo -e "\n=== Checking ${description} ==="
    resource_exists=$(az resource show --resource-group $RESOURCE_GROUP --resource-type $resource_type --name $resource_name --query "name" -o tsv 2>/dev/null)
    
    if [ "$resource_exists" == "$resource_name" ]; then
        echo -e "${GREEN}✓ ${description} exists: ${resource_name}${NC}"
        return 0
    else
        echo -e "${RED}✗ ${description} not found: ${resource_name}${NC}"
        return 1
    fi
}

# Function to validate component connections
validate_connection() {
    source=$1
    target=$2
    validation_command=$3
    description=$4

    echo -e "\n=== Validating connection: ${description} ==="
    eval $validation_command
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Connection validated: ${description}${NC}"
        return 0
    else
        echo -e "${RED}✗ Connection failed: ${description}${NC}"
        return 1
    fi
}

# Check Resource Group
check_resource "Microsoft.Resources/resourceGroups" "$RESOURCE_GROUP" "Resource Group"

# Check Virtual Networks
check_resource "Microsoft.Network/virtualNetworks" "${RESOURCE_PREFIX}-${ENVIRONMENT_NAME}-frontend-vnet" "Frontend Virtual Network"
check_resource "Microsoft.Network/virtualNetworks" "${RESOURCE_PREFIX}-${ENVIRONMENT_NAME}-backend-vnet" "Backend Virtual Network"

# Check Network Security Groups
check_resource "Microsoft.Network/networkSecurityGroups" "${RESOURCE_PREFIX}-${ENVIRONMENT_NAME}-waf-nsg" "WAF NSG"
check_resource "Microsoft.Network/networkSecurityGroups" "${RESOURCE_PREFIX}-${ENVIRONMENT_NAME}-appservice-nsg" "App Service NSG"
check_resource "Microsoft.Network/networkSecurityGroups" "${RESOURCE_PREFIX}-${ENVIRONMENT_NAME}-database-nsg" "Database NSG"
check_resource "Microsoft.Network/networkSecurityGroups" "${RESOURCE_PREFIX}-${ENVIRONMENT_NAME}-keyvault-nsg" "Key Vault NSG"

# Check App Service
check_resource "Microsoft.Web/sites" "${RESOURCE_PREFIX}-${ENVIRONMENT_NAME}-app" "App Service"

# Check App Service Plan
check_resource "Microsoft.Web/serverfarms" "${RESOURCE_PREFIX}-${ENVIRONMENT_NAME}-asp" "App Service Plan"

# Check SQL Server and Database
check_resource "Microsoft.Sql/servers" "${RESOURCE_PREFIX}-${ENVIRONMENT_NAME}-sqlserver" "SQL Server"
check_resource "Microsoft.Sql/servers/databases" "${RESOURCE_PREFIX}-${ENVIRONMENT_NAME}-sqlserver/${RESOURCE_PREFIX}-${ENVIRONMENT_NAME}-sqldb" "SQL Database"

# Check Key Vault
check_resource "Microsoft.KeyVault/vaults" "${RESOURCE_PREFIX}-${ENVIRONMENT_NAME}-kv" "Key Vault"

# Check Web Application Firewall
check_resource "Microsoft.Network/applicationGateways" "${RESOURCE_PREFIX}-${ENVIRONMENT_NAME}-waf" "Web Application Firewall"

# Check Private Endpoints
check_resource "Microsoft.Network/privateEndpoints" "${RESOURCE_PREFIX}-${ENVIRONMENT_NAME}-sqlserver-pe" "SQL Server Private Endpoint"
check_resource "Microsoft.Network/privateEndpoints" "${RESOURCE_PREFIX}-${ENVIRONMENT_NAME}-kv-pe" "Key Vault Private Endpoint"

# Check VNet Peering
echo -e "\n=== Checking VNet Peering ==="
FRONTEND_TO_BACKEND_PEERING=$(az network vnet peering show \
  --resource-group $RESOURCE_GROUP \
  --vnet-name ${RESOURCE_PREFIX}-${ENVIRONMENT_NAME}-frontend-vnet \
  --name "${RESOURCE_PREFIX}-${ENVIRONMENT_NAME}-frontend-vnet-to-${RESOURCE_PREFIX}-${ENVIRONMENT_NAME}-backend-vnet" \
  --query "peeringState" -o tsv 2>/dev/null)

if [ "$FRONTEND_TO_BACKEND_PEERING" == "Connected" ]; then
    echo -e "${GREEN}✓ VNet peering is connected${NC}"
else
    echo -e "${RED}✗ VNet peering is not connected or doesn't exist${NC}"
fi

# Check WAF Health Probe
echo -e "\n=== Checking WAF Health Probe Configuration ==="
WAF_HEALTH_PROBE=$(az network application-gateway probe show \
  --resource-group $RESOURCE_GROUP \
  --gateway-name ${RESOURCE_PREFIX}-${ENVIRONMENT_NAME}-waf \
  --name appServiceHealthProbe \
  --query "path" -o tsv 2>/dev/null)

if [ "$WAF_HEALTH_PROBE" == "/api/health" ]; then
    echo -e "${GREEN}✓ WAF health probe properly configured to /api/health${NC}"
else
    echo -e "${RED}✗ WAF health probe not configured correctly${NC}"
fi

# Check App Service Health Endpoint Configuration
echo -e "\n=== Checking App Service Health Endpoint Configuration ==="
APP_HEALTH_PATH=$(az webapp config show \
  --resource-group $RESOURCE_GROUP \
  --name ${RESOURCE_PREFIX}-${ENVIRONMENT_NAME}-app \
  --query "healthCheckPath" -o tsv 2>/dev/null)

if [ "$APP_HEALTH_PATH" == "/api/health" ]; then
    echo -e "${GREEN}✓ App Service health check path properly configured to /api/health${NC}"
else
    echo -e "${RED}✗ App Service health check path not configured correctly${NC}"
fi

# Check App Service Connection to SQL Database
echo -e "\n=== Checking App Service connection to SQL Database ==="
echo -e "${YELLOW}Note: This test would typically be performed using a custom test endpoint on the App Service.${NC}"
echo -e "${YELLOW}For a complete test, deploy an application that can validate database connectivity.${NC}"

# Check Key Vault Secrets
echo -e "\n=== Checking Key Vault Secrets ==="
SQL_ADMIN_USERNAME_SECRET=$(az keyvault secret show \
  --vault-name ${RESOURCE_PREFIX}-${ENVIRONMENT_NAME}-kv \
  --name sqlAdminLogin \
  --query "name" -o tsv 2>/dev/null)

if [ "$SQL_ADMIN_USERNAME_SECRET" == "sqlAdminLogin" ]; then
    echo -e "${GREEN}✓ SQL Admin Username secret exists in Key Vault${NC}"
else
    echo -e "${RED}✗ SQL Admin Username secret not found in Key Vault${NC}"
fi

# Check WAF Public IP
echo -e "\n=== Checking WAF Public IP ==="
WAF_PUBLIC_IP=$(az network public-ip show \
  --resource-group $RESOURCE_GROUP \
  --name ${RESOURCE_PREFIX}-${ENVIRONMENT_NAME}-waf-pip \
  --query "ipAddress" -o tsv 2>/dev/null)

if [ -n "$WAF_PUBLIC_IP" ]; then
    echo -e "${GREEN}✓ WAF Public IP address: $WAF_PUBLIC_IP${NC}"
else
    echo -e "${RED}✗ WAF Public IP not found${NC}"
fi

echo -e "\n=== Validation complete ==="
