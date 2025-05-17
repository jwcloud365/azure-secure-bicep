# Deployment script for Azure infrastructure
# This script deploys the entire infrastructure using Bicep templates

# Configuration
Write-Host "Loading configuration..." -ForegroundColor Cyan
$SubscriptionId = "your-subscription-id"
$TenantId = "your-tenant-id"
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
