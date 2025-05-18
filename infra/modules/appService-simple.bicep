/*
  Simplified App Service Module
  
  This module creates an App Service Plan and App Service (web app)
  without VNet integration for simplicity.
*/

// ------------- Parameters -------------
@description('The Azure region for all resources')
param location string

@description('Resource name prefix')
param prefix string

@description('Environment name (dev, test, prod)')
param environment string

@description('The fully qualified domain name of the SQL Server')
param sqlServerFqdn string

@description('The name of the SQL Database')
param sqlDatabaseName string

@description('Tags to apply to resources')
param tags object = {}

// ------------- Variables -------------
var appServicePlanName = '${prefix}-${environment}-asp'
var appServiceName = '${prefix}-${environment}-app'

// ------------- Resources -------------

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: {
    name: 'B1'
    tier: 'Basic'
  }
  properties: {
    reserved: false // false for Windows, true for Linux
  }
}

// App Service
resource appService 'Microsoft.Web/sites@2021-02-01' = {
  name: appServiceName
  location: location
  tags: tags
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      http20Enabled: true
      appSettings: [
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~16'
        }
        {
          name: 'DATABASE_SERVER'
          value: sqlServerFqdn
        }
        {
          name: 'DATABASE_NAME'
          value: sqlDatabaseName
        }
        {
          name: 'DATABASE_USERNAME'
          value: '@Microsoft.KeyVault(SecretUri=https://${prefix}-${environment}-kv.vault.azure.net/secrets/sqlAdminLogin/)'
        }
        {
          name: 'DATABASE_PASSWORD'
          value: '@Microsoft.KeyVault(SecretUri=https://${prefix}-${environment}-kv.vault.azure.net/secrets/sqlAdminPassword/)'
        }
      ]
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// ------------- Outputs -------------
output appServiceId string = appService.id
output appServiceName string = appService.name
output appServiceHostName string = appService.properties.defaultHostName
output appServiceUrl string = 'https://${appService.properties.defaultHostName}'
