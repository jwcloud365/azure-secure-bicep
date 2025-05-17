# Deployment script for Azure infrastructure
# This script deploys the entire infrastructure using Bicep templates

# Configuration
Write-Host "Loading configuration..." -ForegroundColor Cyan
$SubscriptionId = "6d505432-f45f-4fb8-9afb-a5c761876cd3"
$TenantId = "24716ce3-de3f-46ef-a555-0dd2c9e293d8"
$Location = "eastus"
$EnvironmentName = "dev"
$ResourceNamePrefix = "contoso"

# Login and set subscription
Write-Host "Logging into Azure..." -ForegroundColor Cyan
az login --tenant $TenantId
az account set --subscription $SubscriptionId

# Deploy infrastructure
Write-Host "Deploying infrastructure..." -ForegroundColor Cyan
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$deploymentName = "$ResourceNamePrefix-$EnvironmentName-deployment-$timestamp"

az deployment sub create `
  --location $Location `
  --template-file ./infra/main.bicep `
  --parameters ./infra/main.parameters.json `
  --name $deploymentName

Write-Host "Deployment completed successfully!" -ForegroundColor Green
