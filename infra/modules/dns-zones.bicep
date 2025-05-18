/*
  Private DNS Zones Module
  
  This module creates Private DNS Zones for Azure services with private endpoints.
*/

// ------------- Parameters -------------
@description('The Azure region for all resources')
param location string = 'global'

@description('Resource name prefix')
param prefix string

@description('Environment name (dev, test, prod)')
param environment string

@description('Frontend VNet ID')
param frontendVNetId string

@description('Backend VNet ID')
param backendVNetId string

@description('Tags to apply to resources')
param tags object = {}

// ------------- Variables -------------
var sqlPrivateDnsZoneName = 'privatelink.database.windows.net'
var keyVaultPrivateDnsZoneName = 'privatelink.vaultcore.azure.net'
var privateDnsZoneSqlName = replace(sqlPrivateDnsZoneName, '.', '-')

// ------------- Resources -------------

// SQL Private DNS Zone
resource sqlPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: sqlPrivateDnsZoneName
  location: location
  tags: tags
}

resource sqlPrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: sqlPrivateDnsZone
  name: '${privateDnsZoneSqlName}-link'
  location: location
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: frontendVNetId
    }
  }
}

// Key Vault Private DNS Zone
resource keyVaultPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: keyVaultPrivateDnsZoneName
  location: location
  tags: tags
}

resource keyVaultPrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: keyVaultPrivateDnsZone
  name: 'keyVaultPrivateDnsZone-link'
  location: location
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: frontendVNetId
    }
  }
}

// ------------- Outputs -------------
output sqlPrivateDnsZoneId string = sqlPrivateDnsZone.id
output keyVaultPrivateDnsZoneId string = keyVaultPrivateDnsZone.id
