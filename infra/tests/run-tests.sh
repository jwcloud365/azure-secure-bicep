#!/bin/bash

# Combined test script for App Service and SQL Database
# This script validates that the deployed Azure resources are working correctly

# Exit on error
set -e

# Configuration
SUBSCRIPTION_ID="6d505432-f45f-4fb8-9afb-a5c761876cd3"
RESOURCE_GROUP="azuresecure-dev-rg"
APP_SERVICE_PLAN_NAME="azuresecure-dev-asp"
APP_SERVICE_NAME="azuresecure-dev-app"
SQL_SERVER_NAME="azuresecure-dev-sqlserver"
SQL_DATABASE_NAME="azuresecure-dev-db"
SQL_PE_NAME="${SQL_SERVER_NAME}-pe"
KEY_VAULT_NAME="azuresecure-dev-kv"

# Login and set subscription
echo "Logging into Azure..."
az account set --subscription $SUBSCRIPTION_ID

echo "===== TESTING APP SERVICE COMPONENTS ====="

# Test App Service Plan existence
echo "Testing App Service Plan existence..."
APP_SERVICE_PLAN=$(az appservice plan show --resource-group $RESOURCE_GROUP --name $APP_SERVICE_PLAN_NAME 2>/dev/null)
if [ $? -ne 0 ]; then
  echo "❌ ERROR: App Service Plan not found!"
else
  echo "✅ App Service Plan exists."

  # Verify App Service Plan SKU without jq
  SKU=$(echo $APP_SERVICE_PLAN | grep -o '"name": *"[^"]*"' | grep -o '"[^"]*"$' | tr -d '"')
  echo "   - SKU: $SKU"
fi

# Test App Service existence
echo "Testing App Service existence..."
APP_SERVICE=$(az webapp show --resource-group $RESOURCE_GROUP --name $APP_SERVICE_NAME 2>/dev/null)
if [ $? -ne 0 ]; then
  echo "❌ ERROR: App Service not found!"
else
  echo "✅ App Service exists."

  # Verify HTTPS Only without jq
  if echo "$APP_SERVICE" | grep -q '"httpsOnly": true'; then
    echo "✅ App Service HTTPS Only setting is enabled."
  else
    echo "❌ App Service HTTPS Only setting is not enabled!"
  fi

  # Verify VNet integration
  VNET_INTEGRATION=$(az webapp vnet-integration list --resource-group $RESOURCE_GROUP --name $APP_SERVICE_NAME 2>/dev/null)
  if [ -z "$VNET_INTEGRATION" ] || [ "$VNET_INTEGRATION" == "[]" ]; then
    echo "❌ App Service VNet integration is not configured!"
  else
    echo "✅ App Service VNet integration is configured."
  fi
  
  # Get App Service URL
  APP_URL="https://${APP_SERVICE_NAME}.azurewebsites.net"
  echo "   - App Service URL: $APP_URL"
  
  # Test App Service health endpoint
  echo "Testing App Service health endpoint (note this may fail as expected due to WAF)..."
  curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 "$APP_URL/api/health" || echo " (expected to fail due to WAF)"
fi

echo "===== TESTING DATABASE COMPONENTS ====="

# Test SQL Server existence
echo "Testing SQL Server existence..."
SQL_SERVER=$(az sql server show --resource-group $RESOURCE_GROUP --name $SQL_SERVER_NAME 2>/dev/null)
if [ $? -ne 0 ]; then
  echo "❌ ERROR: SQL Server not found!"
else
  echo "✅ SQL Server exists."

  # Verify public network access without jq
  if echo "$SQL_SERVER" | grep -q '"publicNetworkAccess": *"Disabled"'; then
    echo "✅ SQL Server public network access is correctly disabled."
  else
    echo "❌ SQL Server public network access is not disabled!"
  fi
fi

# Test SQL Database existence
echo "Testing SQL Database existence..."
SQL_DATABASE=$(az sql db show --resource-group $RESOURCE_GROUP --server $SQL_SERVER_NAME --name $SQL_DATABASE_NAME 2>/dev/null)
if [ $? -ne 0 ]; then
  echo "❌ ERROR: SQL Database not found!"
else
  echo "✅ SQL Database exists."
  # Extract status without jq
  DB_STATUS=$(echo $SQL_DATABASE | grep -o '"status": *"[^"]*"' | grep -o '"[^"]*"$' | tr -d '"')
  echo "   - Status: $DB_STATUS"
fi

# Test Private Endpoint existence
echo "Testing Private Endpoint existence..."
PRIVATE_ENDPOINT=$(az network private-endpoint show --resource-group $RESOURCE_GROUP --name $SQL_PE_NAME 2>/dev/null)
if [ $? -ne 0 ]; then
  echo "❌ ERROR: SQL Private Endpoint not found!"
else
  echo "✅ SQL Private Endpoint exists."
  PE_ID=$(echo $PRIVATE_ENDPOINT | grep -o '"id": *"[^"]*"' | head -1 | grep -o '"[^"]*"$' | tr -d '"')
  echo "   - Private Endpoint ID: $PE_ID"
fi

echo "===== TESTING KEY VAULT ====="

# Test Key Vault existence
echo "Testing Key Vault existence..."
KEY_VAULT=$(az keyvault show --resource-group $RESOURCE_GROUP --name $KEY_VAULT_NAME 2>/dev/null)
if [ $? -ne 0 ]; then
  echo "❌ ERROR: Key Vault not found!"
else
  echo "✅ Key Vault exists."
  
  # Verify if SQL credentials exist in Key Vault
  echo "Testing SQL credentials in Key Vault..."
  SQL_USER_SECRET=$(az keyvault secret list --vault-name $KEY_VAULT_NAME --query "[?name=='sqlAdminUsername']" 2>/dev/null)
  SQL_PASS_SECRET=$(az keyvault secret list --vault-name $KEY_VAULT_NAME --query "[?name=='sqlAdminPassword']" 2>/dev/null)
  
  if [ -z "$SQL_USER_SECRET" ] || [ "$SQL_USER_SECRET" == "[]" ]; then
    echo "❌ SQL Admin Username secret not found in Key Vault!"
  else
    echo "✅ SQL Admin Username secret exists in Key Vault."
  fi
  
  if [ -z "$SQL_PASS_SECRET" ] || [ "$SQL_PASS_SECRET" == "[]" ]; then
    echo "❌ SQL Admin Password secret not found in Key Vault!"
  else
    echo "✅ SQL Admin Password secret exists in Key Vault."
  fi
fi

echo "===== TEST SUMMARY ====="
echo "App Service and database tests completed."
echo "Check the output above for any failures."
