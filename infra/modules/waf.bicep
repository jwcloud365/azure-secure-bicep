/*
  WAF Module
  
  This module creates a Web Application Firewall using Application Gateway WAF_v2 SKU,
  which protects the App Service from internet-based attacks.
*/

// ------------- Parameters -------------
@description('The Azure region for all resources')
param location string

@description('Resource name prefix')
param prefix string

@description('Environment name (dev, test, prod)')
param environment string

@description('The subnet ID for the WAF')
param wafSubnetId string

@description('The host name of the App Service')
param appServiceHostName string

@description('Tags to apply to resources')
param tags object = {}

// ------------- Variables -------------
var wafName = '${prefix}-${environment}-waf'
var wafPublicIpName = '${prefix}-${environment}-waf-pip'

// ------------- Resources -------------

// Public IP for WAF
resource wafPublicIp 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: wafPublicIpName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Web Application Firewall (Application Gateway)
resource waf 'Microsoft.Network/applicationGateways@2021-05-01' = {
  name: wafName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
      capacity: 2
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: wafSubnetId
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          publicIPAddress: {
            id: wafPublicIp.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'appGatewayFrontendPort'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appServiceBackendPool'
        properties: {
          backendAddresses: [
            {
              fqdn: appServiceHostName
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appServiceBackendHttpSettings'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          requestTimeout: 20
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', wafName, 'appServiceHealthProbe')
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'appServiceHttpsListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', wafName, 'appGatewayFrontendIP')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', wafName, 'appGatewayFrontendPort')
          }
          protocol: 'Https'
          sslCertificate: null // Use a custom domain and certificate in production
          requireServerNameIndication: false
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'appServiceRoutingRule'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', wafName, 'appServiceHttpsListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', wafName, 'appServiceBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', wafName, 'appServiceBackendHttpSettings')
          }
        }
      }
    ]
    webApplicationFirewallConfiguration: {
      enabled: true
      firewallMode: 'Prevention'
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.2'
    }
    probes: [
      {
        name: 'appServiceHealthProbe'
        properties: {
          protocol: 'Https'
          path: '/'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: true
          minServers: 0
          match: {
            statusCodes: [
              '200-399'
            ]
          }
        }
      }
    ]
  }
}

// ------------- Outputs -------------
output wafId string = waf.id
output wafName string = waf.name
output wafPublicIpAddress string = wafPublicIp.properties.ipAddress
