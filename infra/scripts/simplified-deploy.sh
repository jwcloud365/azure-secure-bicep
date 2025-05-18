#!/bin/bash

# Simplified deployment script for Azure infrastructure
# This script deploys the entire infrastructure step by step

# Exit on error
set -e

# Configuration
echo "=== Setting up deployment configuration ==="
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)
LOCATION="northeurope"
ENVIRONMENT="dev"
PREFIX="contoso"
UNIQUE_SUFFIX=$(openssl rand -hex 4)
RG_NAME="${PREFIX}-${ENVIRONMENT}-rg"

echo "Subscription ID: $SUBSCRIPTION_ID"
echo "Location: $LOCATION"
echo "Resource Group: $RG_NAME"
echo "Unique Suffix: $UNIQUE_SUFFIX"

# Delete existing resource group if it exists
echo "=== Checking for existing resource group ==="
if az group show -g $RG_NAME &>/dev/null; then
  echo "Resource group $RG_NAME exists. Deleting..."
  az group delete -g $RG_NAME --yes --no-wait
  
  echo "Waiting for resource group deletion to complete..."
  while az group show -g $RG_NAME &>/dev/null; do
    echo "Resource group still exists. Waiting 10 seconds..."
    sleep 10
  done
  echo "Resource group deleted."
fi

# Create a new resource group
echo "=== Creating resource group ==="
az group create --name $RG_NAME --location $LOCATION

# Deploy networking resources
echo "=== Deploying networking resources ==="
az deployment group create \
  --resource-group $RG_NAME \
  --template-file ./infra/modules/networking.bicep \
  --parameters \
    location=$LOCATION \
    prefix=$PREFIX \
    environment=$ENVIRONMENT

# Get subnet IDs
echo "=== Getting subnet IDs ==="
WAF_SUBNET_ID=$(az network vnet subnet show \
  --resource-group $RG_NAME \
  --vnet-name "${PREFIX}-${ENVIRONMENT}-frontend-vnet" \
  --name "waf-subnet" \
  --query "id" -o tsv)

APP_SERVICE_SUBNET_ID=$(az network vnet subnet show \
  --resource-group $RG_NAME \
  --vnet-name "${PREFIX}-${ENVIRONMENT}-frontend-vnet" \
  --name "appservice-subnet" \
  --query "id" -o tsv)

KEY_VAULT_SUBNET_ID=$(az network vnet subnet show \
  --resource-group $RG_NAME \
  --vnet-name "${PREFIX}-${ENVIRONMENT}-frontend-vnet" \
  --name "keyvault-subnet" \
  --query "id" -o tsv)

DATABASE_SUBNET_ID=$(az network vnet subnet show \
  --resource-group $RG_NAME \
  --vnet-name "${PREFIX}-${ENVIRONMENT}-backend-vnet" \
  --name "database-subnet" \
  --query "id" -o tsv)

# Get current user's object ID for Key Vault access
echo "=== Getting current user's Azure AD Object ID ==="
CURRENT_USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)

# Deploy database
echo "=== Deploying SQL Database ==="
az deployment group create \
  --resource-group $RG_NAME \
  --template-file ./infra/modules/database.bicep \
  --parameters \
    location=$LOCATION \
    prefix=$PREFIX \
    environment=$ENVIRONMENT \
    subnetId=$DATABASE_SUBNET_ID \
    administratorLogin="sqlAdmin" \
    administratorLoginPassword="P@ssw0rd1234!"

# Get SQL Server FQDN
SQL_SERVER_FQDN=$(az sql server list \
  --resource-group $RG_NAME \
  --query "[0].fullyQualifiedDomainName" -o tsv)

SQL_DATABASE_NAME="${PREFIX}-${ENVIRONMENT}-sqldb"

# Deploy App Service
echo "=== Deploying App Service ==="
az deployment group create \
  --resource-group $RG_NAME \
  --template-file ./infra/modules/appService.bicep \
  --parameters \
    location=$LOCATION \
    prefix=$PREFIX \
    environment=$ENVIRONMENT \
    subnetId=$APP_SERVICE_SUBNET_ID \
    sqlServerFqdn=$SQL_SERVER_FQDN \
    sqlDatabaseName=$SQL_DATABASE_NAME

# Get App Service hostname
APP_SERVICE_HOSTNAME=$(az webapp list \
  --resource-group $RG_NAME \
  --query "[0].defaultHostName" -o tsv)

# Deploy WAF
echo "=== Deploying WAF (Application Gateway) ==="
az deployment group create \
  --resource-group $RG_NAME \
  --template-file ./infra/modules/waf.bicep \
  --parameters \
    location=$LOCATION \
    prefix=$PREFIX \
    environment=$ENVIRONMENT \
    wafSubnetId=$WAF_SUBNET_ID \
    appServiceHostName=$APP_SERVICE_HOSTNAME \
    healthProbePath="/api/health" \
    healthProbeInterval=30 \
    healthProbeTimeout=30 \
    healthProbeUnhealthyThreshold=3

# Get resource IDs for monitoring
APP_SERVICE_ID=$(az webapp list \
  --resource-group $RG_NAME \
  --query "[0].id" -o tsv)

SQL_SERVER_ID=$(az sql server list \
  --resource-group $RG_NAME \
  --query "[0].id" -o tsv)

WAF_ID=$(az network application-gateway list \
  --resource-group $RG_NAME \
  --query "[0].id" -o tsv)

# Deploy monitoring
echo "=== Deploying monitoring resources ==="
az deployment group create \
  --resource-group $RG_NAME \
  --template-file ./infra/modules/monitoring.bicep \
  --parameters \
    location=$LOCATION \
    prefix=$PREFIX \
    environment=$ENVIRONMENT \
    appServiceId=$APP_SERVICE_ID \
    sqlServerId=$SQL_SERVER_ID \
    wafId=$WAF_ID

# Deployment summary
echo "=== Deployment summary ==="
echo "Resource group: $RG_NAME"
echo "App Service URL: https://$APP_SERVICE_HOSTNAME"
echo "SQL Server FQDN: $SQL_SERVER_FQDN"
echo "SQL Database Name: $SQL_DATABASE_NAME"

# WAF Public IP
WAF_PIP=$(az network public-ip list \
  --resource-group $RG_NAME \
  --query "[?contains(name, 'waf')].ipAddress" -o tsv)
echo "WAF Public IP: $WAF_PIP"

echo "=== Deployment completed ==="
