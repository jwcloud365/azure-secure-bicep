#!/bin/bash

# filepath: c:\Users\HP\Documents\Python\VSCode\Biceptest\infra\scripts\modular-deployment.sh
# Modular deployment script that deploys each component separately

# Script settings
set -e  # Exit on error

# Configuration variables
SUBSCRIPTION_ID="6d505432-f45f-4fb8-9afb-a5c761876cd3"
TENANT_ID="24716ce3-de3f-46ef-a555-0dd2c9e293d8"
LOCATION="northeurope"
ENVIRONMENT_NAME="dev"
RESOURCE_NAME_PREFIX="contoso"
RG_NAME="${RESOURCE_NAME_PREFIX}-${ENVIRONMENT_NAME}-rg"

echo "=== Azure Infrastructure Deployment Script ==="
echo "Location: $LOCATION"
echo "Environment: $ENVIRONMENT_NAME"
echo "Resource Group: $RG_NAME"

# Login to Azure
echo "=== Logging into Azure ==="
az login --tenant $TENANT_ID
az account set --subscription $SUBSCRIPTION_ID
az account show

# Delete resource group if it exists
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
NETWORKING_DEPLOYMENT_NAME="networking-deployment-$(date +%s)"
az deployment group create \
  --name $NETWORKING_DEPLOYMENT_NAME \
  --resource-group $RG_NAME \
  --template-file ./infra/modules/networking.bicep \
  --parameters \
    prefix=$RESOURCE_NAME_PREFIX \
    environment=$ENVIRONMENT_NAME \
    location=$LOCATION

# Get subnet IDs
echo "=== Getting subnet IDs ==="
FRONTEND_VNET_ID=$(az deployment group show -g $RG_NAME -n $NETWORKING_DEPLOYMENT_NAME --query "properties.outputs.frontendVNetId.value" -o tsv)
BACKEND_VNET_ID=$(az deployment group show -g $RG_NAME -n $NETWORKING_DEPLOYMENT_NAME --query "properties.outputs.backendVNetId.value" -o tsv)
WAF_SUBNET_ID=$(az deployment group show -g $RG_NAME -n $NETWORKING_DEPLOYMENT_NAME --query "properties.outputs.wafSubnetId.value" -o tsv)
APP_SERVICE_SUBNET_ID=$(az deployment group show -g $RG_NAME -n $NETWORKING_DEPLOYMENT_NAME --query "properties.outputs.appServiceSubnetId.value" -o tsv)
KEY_VAULT_SUBNET_ID=$(az deployment group show -g $RG_NAME -n $NETWORKING_DEPLOYMENT_NAME --query "properties.outputs.keyVaultSubnetId.value" -o tsv)
DATABASE_SUBNET_ID=$(az deployment group show -g $RG_NAME -n $NETWORKING_DEPLOYMENT_NAME --query "properties.outputs.databaseSubnetId.value" -o tsv)
SQL_PRIVATE_DNS_ZONE_ID=$(az deployment group show -g $RG_NAME -n $NETWORKING_DEPLOYMENT_NAME --query "properties.outputs.sqlPrivateDnsZoneId.value" -o tsv)
KEY_VAULT_PRIVATE_DNS_ZONE_ID=$(az deployment group show -g $RG_NAME -n $NETWORKING_DEPLOYMENT_NAME --query "properties.outputs.keyVaultPrivateDnsZoneId.value" -o tsv)

echo "Frontend VNet ID: $FRONTEND_VNET_ID"
echo "Backend VNet ID: $BACKEND_VNET_ID"
echo "WAF Subnet ID: $WAF_SUBNET_ID"
echo "App Service Subnet ID: $APP_SERVICE_SUBNET_ID"
echo "Key Vault Subnet ID: $KEY_VAULT_SUBNET_ID"
echo "Database Subnet ID: $DATABASE_SUBNET_ID"
echo "SQL Private DNS Zone ID: $SQL_PRIVATE_DNS_ZONE_ID"
echo "Key Vault Private DNS Zone ID: $KEY_VAULT_PRIVATE_DNS_ZONE_ID"

# Get current user's object ID for Key Vault access
echo "=== Getting current user's Azure AD Object ID ==="
CURRENT_USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)
echo "Current User Object ID: $CURRENT_USER_OBJECT_ID"

# Deploy Key Vault
echo "=== Deploying Key Vault ==="
KEY_VAULT_DEPLOYMENT_NAME="keyvault-deployment-$(date +%s)"
az deployment group create \
  --name $KEY_VAULT_DEPLOYMENT_NAME \
  --resource-group $RG_NAME \
  --template-file ./infra/modules/keyVault.bicep \
  --parameters \
    prefix=$RESOURCE_NAME_PREFIX \
    environment=$ENVIRONMENT_NAME \
    location=$LOCATION \
    subnetId=$KEY_VAULT_SUBNET_ID \
    accessPrincipalObjectId=$CURRENT_USER_OBJECT_ID \
    sqlAdministratorLogin="sqlAdmin" \
    sqlAdministratorPassword="P@ssw0rd1234!"

# Get Key Vault info
echo "=== Getting Key Vault information ==="
KEY_VAULT_ID=$(az deployment group show -g $RG_NAME -n $KEY_VAULT_DEPLOYMENT_NAME --query "properties.outputs.keyVaultId.value" -o tsv)
KEY_VAULT_NAME=$(az deployment group show -g $RG_NAME -n $KEY_VAULT_DEPLOYMENT_NAME --query "properties.outputs.keyVaultName.value" -o tsv)
KEY_VAULT_URI=$(az deployment group show -g $RG_NAME -n $KEY_VAULT_DEPLOYMENT_NAME --query "properties.outputs.keyVaultUri.value" -o tsv)

echo "Key Vault ID: $KEY_VAULT_ID"
echo "Key Vault Name: $KEY_VAULT_NAME"
echo "Key Vault URI: $KEY_VAULT_URI"

# Deploy SQL Database
echo "=== Deploying SQL Database ==="
DATABASE_DEPLOYMENT_NAME="database-deployment-$(date +%s)"
az deployment group create \
  --name $DATABASE_DEPLOYMENT_NAME \
  --resource-group $RG_NAME \
  --template-file ./infra/modules/database.bicep \
  --parameters \
    prefix=$RESOURCE_NAME_PREFIX \
    environment=$ENVIRONMENT_NAME \
    location=$LOCATION \
    administratorLogin="sqlAdmin" \
    administratorLoginPassword="P@ssw0rd1234!" \
    subnetId=$DATABASE_SUBNET_ID

# Get SQL Server info
echo "=== Getting SQL Server information ==="
SQL_SERVER_ID=$(az deployment group show -g $RG_NAME -n $DATABASE_DEPLOYMENT_NAME --query "properties.outputs.sqlServerId.value" -o tsv)
SQL_SERVER_NAME=$(az deployment group show -g $RG_NAME -n $DATABASE_DEPLOYMENT_NAME --query "properties.outputs.sqlServerName.value" -o tsv)
SQL_SERVER_FQDN=$(az deployment group show -g $RG_NAME -n $DATABASE_DEPLOYMENT_NAME --query "properties.outputs.sqlServerFqdn.value" -o tsv)
SQL_DATABASE_NAME=$(az deployment group show -g $RG_NAME -n $DATABASE_DEPLOYMENT_NAME --query "properties.outputs.sqlDatabaseName.value" -o tsv)

echo "SQL Server ID: $SQL_SERVER_ID"
echo "SQL Server Name: $SQL_SERVER_NAME"
echo "SQL Server FQDN: $SQL_SERVER_FQDN"
echo "SQL Database Name: $SQL_DATABASE_NAME"

# Deploy App Service
echo "=== Deploying App Service ==="
APP_SERVICE_DEPLOYMENT_NAME="appservice-deployment-$(date +%s)"
az deployment group create \
  --name $APP_SERVICE_DEPLOYMENT_NAME \
  --resource-group $RG_NAME \
  --template-file ./infra/modules/appService.bicep \
  --parameters \
    prefix=$RESOURCE_NAME_PREFIX \
    environment=$ENVIRONMENT_NAME \
    location=$LOCATION \
    subnetId=$APP_SERVICE_SUBNET_ID \
    sqlServerFqdn=$SQL_SERVER_FQDN \
    sqlDatabaseName=$SQL_DATABASE_NAME

# Get App Service info
echo "=== Getting App Service information ==="
APP_SERVICE_ID=$(az deployment group show -g $RG_NAME -n $APP_SERVICE_DEPLOYMENT_NAME --query "properties.outputs.appServiceId.value" -o tsv)
APP_SERVICE_NAME=$(az deployment group show -g $RG_NAME -n $APP_SERVICE_DEPLOYMENT_NAME --query "properties.outputs.appServiceName.value" -o tsv)
APP_SERVICE_HOST_NAME=$(az deployment group show -g $RG_NAME -n $APP_SERVICE_DEPLOYMENT_NAME --query "properties.outputs.appServiceHostName.value" -o tsv)
APP_SERVICE_URL=$(az deployment group show -g $RG_NAME -n $APP_SERVICE_DEPLOYMENT_NAME --query "properties.outputs.appServiceUrl.value" -o tsv)

echo "App Service ID: $APP_SERVICE_ID"
echo "App Service Name: $APP_SERVICE_NAME"
echo "App Service Host Name: $APP_SERVICE_HOST_NAME"
echo "App Service URL: $APP_SERVICE_URL"

# Deploy WAF (Application Gateway)
echo "=== Deploying WAF (Application Gateway) ==="
WAF_DEPLOYMENT_NAME="waf-deployment-$(date +%s)"
az deployment group create \
  --name $WAF_DEPLOYMENT_NAME \
  --resource-group $RG_NAME \
  --template-file ./infra/modules/waf.bicep \
  --parameters \
    prefix=$RESOURCE_NAME_PREFIX \
    environment=$ENVIRONMENT_NAME \
    location=$LOCATION \
    wafSubnetId=$WAF_SUBNET_ID \
    appServiceHostName=$APP_SERVICE_HOST_NAME \
    healthProbePath="/api/health" \
    healthProbeInterval=30 \
    healthProbeTimeout=30 \
    healthProbeUnhealthyThreshold=3

# Get WAF info
echo "=== Getting WAF information ==="
WAF_ID=$(az deployment group show -g $RG_NAME -n $WAF_DEPLOYMENT_NAME --query "properties.outputs.wafId.value" -o tsv)
WAF_NAME=$(az deployment group show -g $RG_NAME -n $WAF_DEPLOYMENT_NAME --query "properties.outputs.wafName.value" -o tsv)
WAF_PUBLIC_IP=$(az deployment group show -g $RG_NAME -n $WAF_DEPLOYMENT_NAME --query "properties.outputs.wafPublicIpAddress.value" -o tsv)

echo "WAF ID: $WAF_ID"
echo "WAF Name: $WAF_NAME"
echo "WAF Public IP: $WAF_PUBLIC_IP"

# Deploy Monitoring
echo "=== Deploying Monitoring ==="
MONITORING_DEPLOYMENT_NAME="monitoring-deployment-$(date +%s)"
az deployment group create \
  --name $MONITORING_DEPLOYMENT_NAME \
  --resource-group $RG_NAME \
  --template-file ./infra/modules/monitoring.bicep \
  --parameters \
    prefix=$RESOURCE_NAME_PREFIX \
    environment=$ENVIRONMENT_NAME \
    location=$LOCATION \
    appServiceId=$APP_SERVICE_ID \
    sqlServerId=$SQL_SERVER_ID \
    wafId=$WAF_ID

echo "=== Deployment Summary ==="
echo "Resource Group: $RG_NAME"
echo "App Service URL: $APP_SERVICE_URL"
echo "WAF Public IP: $WAF_PUBLIC_IP"
echo "SQL Server FQDN: $SQL_SERVER_FQDN"
echo "SQL Database Name: $SQL_DATABASE_NAME"
echo "=== Deployment Complete ==="
