/*
  Simplified Key Vault Module
  
  This module creates an Azure Key Vault for securely storing secrets used by other resources.
  Private endpoints are optional.
*/

// ------------- Parameters -------------
@description('The Azure region for all resources')
param location string

@description('Resource name prefix')
param prefix string

@description('Environment name (dev, test, prod)')
param environment string

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
    publicNetworkAccess: 'Enabled'  // Allow public network access initially
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

// ------------- Outputs -------------
output keyVaultId string = keyVault.id
output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
