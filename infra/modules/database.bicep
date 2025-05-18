/*
  Database Module
  
  This module creates an Azure SQL Server and database with private endpoint connectivity.
*/

// ------------- Parameters -------------
@description('The Azure region for all resources')
param location string

@description('Resource name prefix')
param prefix string

@description('Environment name (dev, test, prod)')
param environment string

@description('The administrator login for the SQL server')
param administratorLogin string

@description('The administrator password for the SQL server')
@secure()
param administratorLoginPassword string

@description('The subnet ID for the private endpoint')
param subnetId string

@description('Tags to apply to resources')
param tags object = {}

// ------------- Variables -------------
var sqlServerName = '${prefix}-${environment}-sqlserver'
var sqlDatabaseName = '${prefix}-${environment}-sqldb'
var privateEndpointName = '${sqlServerName}-pe'

// ------------- Resources -------------

// SQL Server
resource sqlServer 'Microsoft.Sql/servers@2021-05-01-preview' = {
  name: sqlServerName
  location: location
  tags: tags
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    publicNetworkAccess: 'Disabled'
    version: '12.0'
  }
}

// SQL Database
resource sqlDatabase 'Microsoft.Sql/servers/databases@2021-05-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
}

// Private Endpoint for SQL Server
resource sqlPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: privateEndpointName
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: sqlServer.id
          groupIds: [
            'sqlServer'
          ]
        }
      }
    ]
  }
}

// Import sqlPrivateDnsZone from networking module
var sqlServerHostname = az.environment().suffixes.sqlServerHostname
var sqlPrivateDnsZoneName = 'privatelink.${sqlServerHostname}'
resource sqlPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: sqlPrivateDnsZoneName
}

// Create DNS Zone Group for Private Endpoint
resource sqlPrivateEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  parent: sqlPrivateEndpoint
  name: 'dnsgroupname'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: sqlPrivateDnsZone.id
        }
      }
    ]
  }
}

// ------------- Outputs -------------
output sqlServerId string = sqlServer.id
output sqlServerName string = sqlServer.name
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output sqlDatabaseName string = sqlDatabase.name
output sqlPrivateEndpointId string = sqlPrivateEndpoint.id
