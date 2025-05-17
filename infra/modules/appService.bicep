/*
  App Service Module
  
  This module creates an App Service Plan and App Service (web app)
  with VNet integration for secure connectivity to the database.
*/

// ------------- Parameters -------------
@description('The Azure region for all resources')
param location string

@description('Resource name prefix')
param prefix string

@description('Environment name (dev, test, prod)')
param environment string

@description('The subnet ID for VNet integration')
param subnetId string

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
    name: 'P1v2'
    tier: 'PremiumV2'
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
    virtualNetworkSubnetId: subnetId
    siteConfig: {
      vnetRouteAllEnabled: true
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'WEBSITE_DNS_SERVER'
          value: '168.63.129.16' // Azure DNS server
        }
        {
          name: 'WEBSITE_VNET_ROUTE_ALL'
          value: '1'
        }
        {
          name: 'DATABASE_CONNECTION_STRING'
          value: 'Server=tcp:${sqlServerFqdn},1433;Initial Catalog=${sqlDatabaseName};Authentication=Active Directory Managed Identity;'
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
