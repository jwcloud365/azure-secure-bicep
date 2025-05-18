#!/bin/bash

# filepath: c:\Users\HP\Documents\Python\VSCode\Biceptest\infra\scripts\deploy-step-by-step.sh
# Step by step deployment script to avoid naming conflicts

# Script settings
set -e  # Exit on error
set -x  # Echo commands for debugging

# Configuration
echo "Loading configuration..."
SUBSCRIPTION_ID="6d505432-f45f-4fb8-9afb-a5c761876cd3"
TENANT_ID="24716ce3-de3f-46ef-a555-0dd2c9e293d8"
LOCATION="northeurope"
ENVIRONMENT_NAME="dev"
RESOURCE_NAME_PREFIX="contoso"
RG_NAME="${RESOURCE_NAME_PREFIX}-${ENVIRONMENT_NAME}-rg"

# Login and set subscription
echo "Logging into Azure..."
az login --tenant $TENANT_ID
az account set --subscription $SUBSCRIPTION_ID
az account show

# Verify files exist
if [ ! -f "./infra/modules/resourceGroup.bicep" ]; then
    echo "ERROR: resourceGroup.bicep file not found!"
    exit 1
fi

# 0. Delete existing resource group if it exists
echo "Checking for existing resource group..."
if az group show --name $RG_NAME &>/dev/null; then
    echo "Deleting existing resource group $RG_NAME..."
    az group delete --name $RG_NAME --yes
fi

# 1. Create Resource Group
echo "Creating resource group..."
az deployment sub create \
  --location $LOCATION \
  --template-file ./infra/modules/resourceGroup.bicep \
  --parameters resourceGroupName=$RG_NAME location=$LOCATION \
  --name "rg-deployment-$(date +%s)"

sleep 10

# 2. Create Networking
echo "Creating networking resources..."
az deployment group create \
  --resource-group $RG_NAME \
  --template-file ./infra/modules/networking.bicep \
  --parameters prefix=$RESOURCE_NAME_PREFIX environment=$ENVIRONMENT_NAME location=$LOCATION \
  --name "networking-deployment-$(date +%s)"

# If it fails, try again with extra wait time
if [ $? -ne 0 ]; then
  echo "Networking deployment failed. Waiting 30 seconds and retrying..."
  sleep 30
  az deployment group create \
    --resource-group $RG_NAME \
    --template-file ./infra/modules/networking.bicep \
    --parameters prefix=$RESOURCE_NAME_PREFIX environment=$ENVIRONMENT_NAME location=$LOCATION \
    --name "networking-deployment-$(date +%s)-retry"
fi

sleep 10

# 3. Create Database
echo "Creating database resources..."
DATABASE_SUBNET_ID=$(az deployment group show --resource-group $RG_NAME --name "networking-deployment-$(date +%s)" --query "properties.outputs.databaseSubnetId.value" -o tsv 2>/dev/null || echo "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Network/virtualNetworks/contoso-dev-backend-vnet/subnets/database-subnet")

DEPLOYMENT_NAME="database-deployment-$(date +%s)"
az deployment group create \
  --resource-group $RG_NAME \
  --template-file ./infra/modules/database.bicep \
  --parameters prefix=$RESOURCE_NAME_PREFIX environment=$ENVIRONMENT_NAME location=$LOCATION \
    administratorLogin=sqlAdmin administratorLoginPassword=P@ssw0rd1234! \
    subnetId="$DATABASE_SUBNET_ID" \
  --name $DEPLOYMENT_NAME

# If it fails, try again with extra wait time
if [ $? -ne 0 ]; then
  echo "Database deployment failed. Waiting 30 seconds and retrying..."
  sleep 30
  DEPLOYMENT_NAME="database-deployment-$(date +%s)-retry"
  az deployment group create \
    --resource-group $RG_NAME \
    --template-file ./infra/modules/database.bicep \
    --parameters prefix=$RESOURCE_NAME_PREFIX environment=$ENVIRONMENT_NAME location=$LOCATION \
      administratorLogin=sqlAdmin administratorLoginPassword=P@ssw0rd1234! \
      subnetId="$DATABASE_SUBNET_ID" \
    --name $DEPLOYMENT_NAME
fi

sleep 10

# Store database outputs
SQL_SERVER_FQDN=$(az sql server show --resource-group $RG_NAME --name "${RESOURCE_NAME_PREFIX}-${ENVIRONMENT_NAME}-sqlserver" --query "fullyQualifiedDomainName" -o tsv 2>/dev/null || echo "${RESOURCE_NAME_PREFIX}-${ENVIRONMENT_NAME}-sqlserver.database.windows.net")
SQL_DATABASE_NAME="${RESOURCE_NAME_PREFIX}-${ENVIRONMENT_NAME}-sqldb"
APP_SERVICE_SUBNET_ID=$(az deployment group show --resource-group $RG_NAME --name "networking-deployment-$(date +%s)" --query "properties.outputs.appServiceSubnetId.value" -o tsv 2>/dev/null || echo "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Network/virtualNetworks/contoso-dev-frontend-vnet/subnets/appservice-subnet")

# 4. Create App Service
echo "Creating App Service resources..."
DEPLOYMENT_NAME="appservice-deployment-$(date +%s)"
az deployment group create \
  --resource-group $RG_NAME \
  --template-file ./infra/modules/appService.bicep \
  --parameters prefix=$RESOURCE_NAME_PREFIX environment=$ENVIRONMENT_NAME location=$LOCATION \
    sqlServerFqdn="$SQL_SERVER_FQDN" sqlDatabaseName="$SQL_DATABASE_NAME" \
    subnetId="$APP_SERVICE_SUBNET_ID" \
  --name $DEPLOYMENT_NAME

# If it fails, try again with extra wait time
if [ $? -ne 0 ]; then
  echo "App Service deployment failed. Waiting 30 seconds and retrying..."
  sleep 30
  DEPLOYMENT_NAME="appservice-deployment-$(date +%s)-retry"
  az deployment group create \
    --resource-group $RG_NAME \
    --template-file ./infra/modules/appService.bicep \
    --parameters prefix=$RESOURCE_NAME_PREFIX environment=$ENVIRONMENT_NAME location=$LOCATION \
      sqlServerFqdn="$SQL_SERVER_FQDN" sqlDatabaseName="$SQL_DATABASE_NAME" \
      subnetId="$APP_SERVICE_SUBNET_ID" \
    --name $DEPLOYMENT_NAME
fi

sleep 10

# Store App Service outputs
APP_SERVICE_HOSTNAME=$(az webapp show --resource-group $RG_NAME --name "${RESOURCE_NAME_PREFIX}-${ENVIRONMENT_NAME}-app" --query "defaultHostName" -o tsv 2>/dev/null || echo "${RESOURCE_NAME_PREFIX}-${ENVIRONMENT_NAME}-app.azurewebsites.net")
APP_SERVICE_ID=$(az webapp show --resource-group $RG_NAME --name "${RESOURCE_NAME_PREFIX}-${ENVIRONMENT_NAME}-app" --query "id" -o tsv 2>/dev/null || echo "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Web/sites/${RESOURCE_NAME_PREFIX}-${ENVIRONMENT_NAME}-app")
WAF_SUBNET_ID=$(az deployment group show --resource-group $RG_NAME --name "networking-deployment-$(date +%s)" --query "properties.outputs.wafSubnetId.value" -o tsv 2>/dev/null || echo "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Network/virtualNetworks/contoso-dev-frontend-vnet/subnets/waf-subnet")

# 5. Create WAF
echo "Creating WAF resources..."
DEPLOYMENT_NAME="waf-deployment-$(date +%s)"
az deployment group create \
  --resource-group $RG_NAME \
  --template-file ./infra/modules/waf.bicep \
  --parameters prefix=$RESOURCE_NAME_PREFIX environment=$ENVIRONMENT_NAME location=$LOCATION \
    appServiceHostName="$APP_SERVICE_HOSTNAME" \
    wafSubnetId="$WAF_SUBNET_ID" \
  --name $DEPLOYMENT_NAME

# If it fails, try again with extra wait time
if [ $? -ne 0 ]; then
  echo "WAF deployment failed. Waiting 30 seconds and retrying..."
  sleep 30
  DEPLOYMENT_NAME="waf-deployment-$(date +%s)-retry"
  az deployment group create \
    --resource-group $RG_NAME \
    --template-file ./infra/modules/waf.bicep \
    --parameters prefix=$RESOURCE_NAME_PREFIX environment=$ENVIRONMENT_NAME location=$LOCATION \
      appServiceHostName="$APP_SERVICE_HOSTNAME" \
      wafSubnetId="$WAF_SUBNET_ID" \
    --name $DEPLOYMENT_NAME
fi

sleep 10

# Store WAF outputs
WAF_NAME="${RESOURCE_NAME_PREFIX}-${ENVIRONMENT_NAME}-waf"
WAF_ID=$(az network application-gateway show --resource-group $RG_NAME --name $WAF_NAME --query "id" -o tsv 2>/dev/null || echo "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Network/applicationGateways/$WAF_NAME")
WAF_PUBLIC_IP=$(az network public-ip show --resource-group $RG_NAME --name "${RESOURCE_NAME_PREFIX}-${ENVIRONMENT_NAME}-waf-pip" --query "ipAddress" -o tsv 2>/dev/null || echo "Not available yet")

# 6. Create Monitoring
echo "Creating monitoring resources..."
DEPLOYMENT_NAME="monitoring-deployment-$(date +%s)"
SQL_SERVER_ID=$(az sql server show --resource-group $RG_NAME --name "${RESOURCE_NAME_PREFIX}-${ENVIRONMENT_NAME}-sqlserver" --query "id" -o tsv 2>/dev/null)

az deployment group create \
  --resource-group $RG_NAME \
  --template-file ./infra/modules/monitoring.bicep \
  --parameters prefix=$RESOURCE_NAME_PREFIX environment=$ENVIRONMENT_NAME location=$LOCATION \
    appServiceId="$APP_SERVICE_ID" sqlServerId="$SQL_SERVER_ID" \
    wafId="$WAF_ID" \
  --name $DEPLOYMENT_NAME

# If it fails, try again with extra wait time
if [ $? -ne 0 ]; then
  echo "Monitoring deployment failed. Waiting 30 seconds and retrying..."
  sleep 30
  DEPLOYMENT_NAME="monitoring-deployment-$(date +%s)-retry"
  az deployment group create \
    --resource-group $RG_NAME \
    --template-file ./infra/modules/monitoring.bicep \
    --parameters prefix=$RESOURCE_NAME_PREFIX environment=$ENVIRONMENT_NAME location=$LOCATION \
      appServiceId="$APP_SERVICE_ID" sqlServerId="$SQL_SERVER_ID" \
      wafId="$WAF_ID" \
    --name $DEPLOYMENT_NAME
fi

echo "Deployment completed successfully!"
echo "Resource Group: $RG_NAME"
echo "App Service URL: https://$APP_SERVICE_HOSTNAME"
echo "WAF Public IP: $WAF_PUBLIC_IP"
echo "SQL Server FQDN: $SQL_SERVER_FQDN"
