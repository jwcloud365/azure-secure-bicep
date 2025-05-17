/*
  Networking Module
  
  This module creates:
  - Frontend VNet with subnets for App Service and WAF
  - Backend VNet with subnet for Database
  - NSGs for each subnet
  - VNet peering between frontend and backend
  - Private DNS zones for private endpoints
*/

// ------------- Parameters -------------
@description('The Azure region for all resources')
param location string

@description('Resource name prefix')
param prefix string

@description('Environment name (dev, test, prod)')
param environment string

@description('Tags to apply to resources')
param tags object = {}

// ------------- Variables -------------
var frontendVNetName = '${prefix}-${environment}-frontend-vnet'
var backendVNetName = '${prefix}-${environment}-backend-vnet'

var frontendAddressPrefix = '10.0.0.0/16'
var backendAddressPrefix = '10.1.0.0/16'

var wafSubnetName = 'waf-subnet'
var appServiceSubnetName = 'appservice-subnet'
var databaseSubnetName = 'database-subnet'

var wafSubnetPrefix = '10.0.0.0/24'
var appServiceSubnetPrefix = '10.0.1.0/24'
var databaseSubnetPrefix = '10.1.0.0/24'

var wafNsgName = '${prefix}-${environment}-waf-nsg'
var appServiceNsgName = '${prefix}-${environment}-appservice-nsg'
var databaseNsgName = '${prefix}-${environment}-database-nsg'

// ------------- Resources -------------

// Network Security Groups
resource wafNsg 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: wafNsgName
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowHTTPInbound'
        properties: {
          priority: 100
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationPortRange: '80'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowHTTPSInbound'
        properties: {
          priority: 110
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowGatewayManagerInbound'
        properties: {
          priority: 120
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'GatewayManager'
          destinationPortRange: '65200-65535'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource appServiceNsg 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: appServiceNsgName
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowWAFInbound'
        properties: {
          priority: 100
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: wafSubnetPrefix
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource databaseNsg 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: databaseNsgName
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowAppServiceInbound'
        properties: {
          priority: 100
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: appServiceSubnetPrefix
          destinationPortRange: '1433'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// Frontend VNet
resource frontendVNet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: frontendVNetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        frontendAddressPrefix
      ]
    }
    subnets: [
      {
        name: wafSubnetName
        properties: {
          addressPrefix: wafSubnetPrefix
          networkSecurityGroup: {
            id: wafNsg.id
          }
        }
      }
      {
        name: appServiceSubnetName
        properties: {
          addressPrefix: appServiceSubnetPrefix
          networkSecurityGroup: {
            id: appServiceNsg.id
          }
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

// Backend VNet
resource backendVNet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: backendVNetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        backendAddressPrefix
      ]
    }
    subnets: [
      {
        name: databaseSubnetName
        properties: {
          addressPrefix: databaseSubnetPrefix
          networkSecurityGroup: {
            id: databaseNsg.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

// VNet Peering (Frontend to Backend)
resource frontendToBackendPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01' = {
  parent: frontendVNet
  name: '${frontendVNetName}-to-${backendVNetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: backendVNet.id
    }
  }
}

// VNet Peering (Backend to Frontend)
resource backendToFrontendPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01' = {
  parent: backendVNet
  name: '${backendVNetName}-to-${frontendVNetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: frontendVNet.id
    }
  }
}

// Private DNS Zones
resource sqlPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.database.windows.net'
  location: 'global'
  tags: tags
}

resource sqlPrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: sqlPrivateDnsZone
  name: '${sqlPrivateDnsZone.name}-link'
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: frontendVNet.id
    }
  }
}

// ------------- Outputs -------------
output frontendVNetId string = frontendVNet.id
output backendVNetId string = backendVNet.id
output wafSubnetId string = '${frontendVNet.id}/subnets/${wafSubnetName}'
output appServiceSubnetId string = '${frontendVNet.id}/subnets/${appServiceSubnetName}'
output databaseSubnetId string = '${backendVNet.id}/subnets/${databaseSubnetName}'
output sqlPrivateDnsZoneId string = sqlPrivateDnsZone.id
