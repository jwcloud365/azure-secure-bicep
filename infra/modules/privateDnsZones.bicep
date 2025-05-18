/*
  Private DNS Zone Module
  
  This module creates Private DNS Zones for Azure services with private endpoints.
*/

// ------------- Parameters -------------
@description('The Azure region for all resources')
param location string

@description('Resource name prefix')
param prefix string

@description('Environment name (dev, test, prod)')
param environment string

@description('The ID of the frontend VNet to link to the private DNS zone')
param frontendVNetId string

@description('The ID of the backend VNet to link to the private DNS zone')
param backendVNetId string

@description('Tags to apply to resources')
param tags object = {}

// ------------- Variables -------------
var sqlPrivateDnsZoneName = 'privatelink.database.windows.net'
var keyVaultPrivateDnsZoneName = 'privatelink.vaultcore.azure.net'

// ------------- Resources -------------

// SQL Server Private DNS Zone
resource sqlPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: sqlPrivateDnsZoneName
  location: 'global'
  tags: tags
}

// Key Vault Private DNS Zone
resource keyVaultPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: keyVaultPrivateDnsZoneName
  location: 'global'
  tags: tags
}

// Frontend VNet Link to SQL Private DNS Zone
resource frontendVNetLinkSql 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${sqlPrivateDnsZone.name}/${prefix}-${environment}-frontend-link'
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: frontendVNetId
    }
  }
}

// Backend VNet Link to SQL Private DNS Zone
resource backendVNetLinkSql 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${sqlPrivateDnsZone.name}/${prefix}-${environment}-backend-link'
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: backendVNetId
    }
  }
}

// Frontend VNet Link to Key Vault Private DNS Zone
resource frontendVNetLinkKeyVault 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${keyVaultPrivateDnsZone.name}/${prefix}-${environment}-frontend-link'
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: frontendVNetId
    }
  }
}

// Backend VNet Link to Key Vault Private DNS Zone
resource backendVNetLinkKeyVault 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${keyVaultPrivateDnsZone.name}/${prefix}-${environment}-backend-link'
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: backendVNetId
    }
  }
}

// ------------- Outputs -------------
output sqlPrivateDnsZoneId string = sqlPrivateDnsZone.id
output keyVaultPrivateDnsZoneId string = keyVaultPrivateDnsZone.id
