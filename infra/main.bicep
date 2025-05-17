/*
  Main Bicep template for Azure infrastructure deployment
  
  This template orchestrates the deployment of all components:
  - Resource Group
  - Virtual Networks and Network Security Groups
  - App Service (Frontend)
  - Azure SQL Database (Backend)
  - Web Application Firewall (Application Gateway)
  - Private Endpoints
  - Monitoring resources
*/

// Target scope is subscription as we're creating resource groups
targetScope = 'subscription'

// ------------- Parameters -------------
@description('The environment name (dev, test, prod)')
param environmentName string

@description('The Azure region for all resources')
param location string

@description('Resource name prefix to ensure global uniqueness')
param resourceNamePrefix string

@description('The administrator login for the SQL server')
@secure()
param sqlAdministratorLogin string

@description('The administrator password for the SQL server')
@secure()
param sqlAdministratorPassword string

// ------------- Variables -------------
var rgName = '${resourceNamePrefix}-${environmentName}-rg'
var tags = {
  Environment: environmentName
  DeployedBy: 'Bicep'
  Project: '${resourceNamePrefix}'
}

// ------------- Resources -------------

// 1. Create Resource Group
module resourceGroup './modules/resourceGroup.bicep' = {
  name: 'resourceGroupDeployment'
  params: {
    resourceGroupName: rgName
    location: location
    tags: tags
  }
}

// 2. Create Network Infrastructure
module networking './modules/networking.bicep' = {
  name: 'networkingDeployment'
  scope: resourceGroup(rgName)
  params: {
    location: location
    prefix: resourceNamePrefix
    environment: environmentName
    tags: tags
  }
  dependsOn: [
    resourceGroup
  ]
}

// 3. Create Azure SQL Database
module database './modules/database.bicep' = {
  name: 'databaseDeployment'
  scope: resourceGroup(rgName)
  params: {
    location: location
    prefix: resourceNamePrefix
    environment: environmentName
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword: sqlAdministratorPassword
    subnetId: networking.outputs.databaseSubnetId
    tags: tags
  }
  dependsOn: [
    networking
  ]
}

// 4. Create App Service with Private Endpoint
module appService './modules/appService.bicep' = {
  name: 'appServiceDeployment'
  scope: resourceGroup(rgName)
  params: {
    location: location
    prefix: resourceNamePrefix
    environment: environmentName
    subnetId: networking.outputs.appServiceSubnetId
    sqlServerFqdn: database.outputs.sqlServerFqdn
    sqlDatabaseName: database.outputs.sqlDatabaseName
    tags: tags
  }
  dependsOn: [
    database
  ]
}

// 5. Create Web Application Firewall (Application Gateway)
module waf './modules/waf.bicep' = {
  name: 'wafDeployment'
  scope: resourceGroup(rgName)
  params: {
    location: location
    prefix: resourceNamePrefix
    environment: environmentName
    wafSubnetId: networking.outputs.wafSubnetId
    appServiceHostName: appService.outputs.appServiceHostName
    tags: tags
  }
  dependsOn: [
    appService
  ]
}

// 6. Create Monitoring Resources
module monitoring './modules/monitoring.bicep' = {
  name: 'monitoringDeployment'
  scope: resourceGroup(rgName)
  params: {
    location: location
    prefix: resourceNamePrefix
    environment: environmentName
    appServiceId: appService.outputs.appServiceId
    sqlServerId: database.outputs.sqlServerId
    wafId: waf.outputs.wafId
    tags: tags
  }
  dependsOn: [
    waf
  ]
}

// ------------- Outputs -------------
output resourceGroupName string = rgName
output appServiceUrl string = appService.outputs.appServiceUrl
output wafPublicIpAddress string = waf.outputs.wafPublicIpAddress
output sqlServerFqdn string = database.outputs.sqlServerFqdn
