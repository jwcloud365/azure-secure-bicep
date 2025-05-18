#!/bin/bash

# Infrastructure Validation Script
# This script validates the deployed infrastructure components

# Configuration variables
RESOURCE_GROUP="azuresecure-dev-rg"
PREFIX="azuresecure"
ENV="dev"

# Resource names
APP_NAME="${PREFIX}-${ENV}-app"
SQL_SERVER_NAME="${PREFIX}-${ENV}-sqlserver"
SQL_DB_NAME="${PREFIX}-${ENV}-db"
KEY_VAULT_NAME="${PREFIX}-${ENV}-kv"
WAF_NAME="${PREFIX}-${ENV}-waf"
WAF_PIP_NAME="${PREFIX}-${ENV}-waf-pip"

echo "=== Validating Azure Infrastructure ==="

# Function to check resource existence
check_resource() {
    resource_type=$1
    resource_name=$2
    display_name=$3
    
    echo -n "Checking $display_name... "
    if az resource show --resource-group $RESOURCE_GROUP --resource-type $resource_type --name $resource_name &> /dev/null; then
        echo "FOUND"
        return 0
    else
        echo "NOT FOUND"
        return 1
    fi
}

# 1. Validate resource group
echo -n "Checking resource group... "
if az group show --name $RESOURCE_GROUP &> /dev/null; then
    echo "FOUND"
else
    echo "NOT FOUND - Critical error"
    exit 1
fi

# 2. Validate App Service
check_resource "Microsoft.Web/sites" $APP_NAME "App Service"

# 3. Validate SQL Server and database
check_resource "Microsoft.Sql/servers" $SQL_SERVER_NAME "SQL Server"

# Check if SQL Database exists
echo -n "Checking SQL Database... "
if az sql db show --resource-group $RESOURCE_GROUP --server $SQL_SERVER_NAME --name $SQL_DB_NAME &> /dev/null; then
    echo "FOUND"
else
    echo "NOT FOUND"
fi

# 4. Validate Key Vault
check_resource "Microsoft.KeyVault/vaults" $KEY_VAULT_NAME "Key Vault"

# 5. Validate WAF (Application Gateway)
check_resource "Microsoft.Network/applicationGateways" $WAF_NAME "Application Gateway"

# 6. Validate private endpoints
echo -n "Checking SQL private endpoint... "
if az network private-endpoint list --resource-group $RESOURCE_GROUP --query "[?contains(name, '$SQL_SERVER_NAME')]" --output tsv | grep -q "$SQL_SERVER_NAME"; then
    echo "FOUND"
else
    echo "NOT FOUND"
fi

echo -n "Checking Key Vault private endpoint... "
if az network private-endpoint list --resource-group $RESOURCE_GROUP --query "[?contains(name, '$KEY_VAULT_NAME')]" --output tsv | grep -q "$KEY_VAULT_NAME"; then
    echo "FOUND"
else
    echo "NOT FOUND"
fi

# 7. Validate App Service VNet integration
echo -n "Checking App Service VNet integration... "
if az webapp vnet-integration list --resource-group $RESOURCE_GROUP --name $APP_NAME --query "[0].id" --output tsv 2>/dev/null | grep -q "virtualNetworks"; then
    echo "FOUND"
else
    echo "NOT FOUND"
fi

# 8. Test WAF connectivity
echo -n "Getting WAF public IP... "
WAF_PUBLIC_IP=$(az network public-ip show \
    --resource-group $RESOURCE_GROUP \
    --name $WAF_PIP_NAME \
    --query ipAddress \
    --output tsv 2>/dev/null)

if [ -n "$WAF_PUBLIC_IP" ]; then
    echo "$WAF_PUBLIC_IP"
    
    echo -n "Testing connectivity to WAF... "
    if curl -k -s -o /dev/null -w "%{http_code}" https://$WAF_PUBLIC_IP | grep -q -E "200|403|301|302"; then
        echo "SUCCESS"
    else
        echo "FAILED"
    fi
else
    echo "NOT FOUND"
fi

# 9. Validate Log Analytics Workspace
echo -n "Checking Log Analytics Workspace... "
if az monitor log-analytics workspace list --resource-group $RESOURCE_GROUP --query "[0].name" --output tsv 2>/dev/null | grep -q "${PREFIX}-${ENV}-law"; then
    echo "FOUND"
else
    echo "NOT FOUND"
fi

# Generate summary report
echo
echo "=== Infrastructure Validation Summary ==="
echo "Resource Group:           $(az group show --name $RESOURCE_GROUP --query properties.provisioningState --output tsv 2>/dev/null || echo 'NOT FOUND')"
echo "App Service:              $(az webapp show --resource-group $RESOURCE_GROUP --name $APP_NAME --query state --output tsv 2>/dev/null || echo 'NOT FOUND')"
echo "SQL Server:               $(az sql server show --resource-group $RESOURCE_GROUP --name $SQL_SERVER_NAME --query state --output tsv 2>/dev/null || echo 'FOUND')"
echo "Key Vault:                $(az keyvault show --resource-group $RESOURCE_GROUP --name $KEY_VAULT_NAME --query properties.provisioningState --output tsv 2>/dev/null || echo 'NOT FOUND')"
echo "WAF (App Gateway):        $(az network application-gateway show --resource-group $RESOURCE_GROUP --name $WAF_NAME --query operationalState --output tsv 2>/dev/null || echo 'NOT FOUND')"
echo "Private Endpoints:        $(az network private-endpoint list --resource-group $RESOURCE_GROUP --query "length(@)" --output tsv 2>/dev/null || echo '0')"
echo "Log Analytics Workspace:  $(az monitor log-analytics workspace list --resource-group $RESOURCE_GROUP --query "[0].provisioningState" --output tsv 2>/dev/null || echo 'NOT FOUND')"
echo

echo "Validation completed!"
