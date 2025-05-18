#!/bin/bash

# Deploy test app to App Service
# This script deploys a simple test page to the App Service

# Configuration
RESOURCE_GROUP="azuresecure-dev-rg"
APP_NAME="azuresecure-dev-app"
APP_FOLDER="/c/Users/HP/Documents/Python/VSCode/biceptest2/azure-secure-bicep/infra/tests/app"

echo "=== Deploying test page to App Service ==="

# Deploy using ZIP deployment
echo "Deploying using ZIP deployment..."
az webapp deployment source config-zip \
  --resource-group $RESOURCE_GROUP \
  --name $APP_NAME \
  --src "$APP_FOLDER/site.zip"

echo "Test page deployment completed!"

# Get the app URL
APP_URL="https://${APP_NAME}.azurewebsites.net"
echo "App URL: $APP_URL"
echo "Open this URL in your browser to verify the deployment."
