#!/bin/bash

# End-to-end deployment test script
# This script tests the end-to-end deployment of the infrastructure

# Exit on error
set -e

# Configuration
SUBSCRIPTION_ID="6d505432-f45f-4fb8-9afb-a5c761876cd3"
TENANT_ID="24716ce3-de3f-46ef-a555-0dd2c9e293d8"
LOCATION="eastus"
ENVIRONMENT_NAME="dev"
RESOURCE_NAME_PREFIX="contoso"
TIMESTAMP=$(date +%Y%m%d%H%M%S)
RESOURCE_GROUP="${RESOURCE_NAME_PREFIX}-${ENVIRONMENT_NAME}-rg"

# Create a temporary parameters file with test values
TEMP_PARAMS_FILE="./infra/main.parameters.temp.json"
cat > $TEMP_PARAMS_FILE << EOF
{
  "\$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "environmentName": {
      "value": "${ENVIRONMENT_NAME}"
    },
    "location": {
      "value": "${LOCATION}"
    },
    "resourceNamePrefix": {
      "value": "${RESOURCE_NAME_PREFIX}"
    },
    "sqlAdministratorLogin": {
      "value": "testadmin"
    },
    "sqlAdministratorPassword": {
      "value": "Test-Password123!"
    }
  }
}
EOF

echo "Login to Azure..."
az login --tenant $TENANT_ID
az account set --subscription $SUBSCRIPTION_ID

echo "Starting end-to-end deployment test..."

# Deploy the infrastructure
echo "Deploying infrastructure..."
DEPLOYMENT_NAME="${RESOURCE_NAME_PREFIX}-${ENVIRONMENT_NAME}-e2e-test-${TIMESTAMP}"

az deployment sub create \
  --location $LOCATION \
  --template-file ./infra/main.bicep \
  --parameters @$TEMP_PARAMS_FILE \
  --name $DEPLOYMENT_NAME

# Run validation tests
echo "Running validation tests..."
./infra/tests/run-all-tests.sh

# Clean up
echo "Cleaning up resources..."
az group delete --name $RESOURCE_GROUP --yes --no-wait

echo "Cleaning up temp files..."
rm $TEMP_PARAMS_FILE

echo "End-to-end test completed successfully!"
echo "Note: Resource group ${RESOURCE_GROUP} is being deleted in the background."
