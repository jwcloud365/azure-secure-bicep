/*
  Key Vault Module
  
  This module creates an Azure Key Vault for securely storing secrets used by other resources.
*/

// ------------- Parameters -------------
@description('The Azure region for all resources')
param location string

@description('Resource name prefix')
param prefix string

@description('Environment name (dev, test, prod)')
param environment string

@description('The ID of the subnet for the private endpoint')
param subnetId string

@description('Object ID of the user or service principal to grant access to Key Vault')
param accessPrincipalObjectId string

@description('SQL Administrator login to store as secret')
@secure()
param sqlAdministratorLogin string = 'sqlAdmin'

@description('SQL Administrator password to store as secret')
@secure()
param sqlAdministratorPassword string = ''

@description('Tags to apply to resources')
param tags object = {}

// ------------- Variables -------------
var keyVaultName = '${prefix}-${environment}-kv'
var privateEndpointName = '${keyVaultName}-pe'

// ------------- Resources -------------

// Azure Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
    enableRbacAuthorization: false
    tenantId: subscription().tenantId
    publicNetworkAccess: 'Disabled'  // For highest security, restrict public network access
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: accessPrincipalObjectId
        permissions: {
          secrets: [
            'get'
            'list'
            'set'
            'delete'
          ]
          certificates: [
            'get'
            'list'
            'create'
            'import'
            'delete'
          ]
          keys: [
            'get'
            'list'
            'create'
            'import'
            'delete'
          ]
        }
      }
    ]
  }
}

// SQL Admin Login Secret
resource sqlAdminLoginSecret 'Microsoft.KeyVault/vaults/secrets@2021-10-01' = {
  parent: keyVault
  name: 'sqlAdminLogin'
  properties: {
    value: sqlAdministratorLogin
  }
}

// SQL Admin Password Secret
resource sqlAdminPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2021-10-01' = if (sqlAdministratorPassword != '') {
  parent: keyVault
  name: 'sqlAdminPassword'
  properties: {
    value: sqlAdministratorPassword
  }
}

// Private Endpoint for Key Vault
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
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
          privateLinkServiceId: keyVault.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
  }
}

// Private DNS Zone Group for Key Vault
resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  name: '${privateEndpoint.name}/default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'keyvault-config'
        properties: {
          privateDnsZoneId: resourceId('Microsoft.Network/privateDnsZones', 'privatelink.vaultcore.azure.net')
        }
      }
    ]
  }
}

// ------------- Outputs -------------
output keyVaultId string = keyVault.id
output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
