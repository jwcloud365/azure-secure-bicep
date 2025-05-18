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

@description('The health probe path for the App Service')
param healthProbePath string = '/api/health'

@description('The health probe interval in seconds')
param healthProbeInterval int = 30

@description('The health probe timeout in seconds')
param healthProbeTimeout int = 30

@description('The health probe unhealthy threshold')
param healthProbeUnhealthyThreshold int = 3

@description('Minimum number of servers that must be available for the probe to report as healthy')
param healthProbeMinServers int = 0 

@description('HTTP status codes to match for probe success')
param healthProbeStatusCodes array = ['200-399']

@description('Whether to use the host name from the backend HTTP settings')
param pickHostNameFromBackendSettings bool = true

@description('Tags to apply to resources')
param tags object = {}

// ------------- Variables -------------
var wafName = '${prefix}-${environment}-waf'
var wafPublicIpName = '${prefix}-${environment}-waf-pip'
var healthProbeName = 'appServiceHealthProbe'

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
            id: resourceId('Microsoft.Network/applicationGateways/probes', wafName, healthProbeName)
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
          }        }
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
        name: healthProbeName
        properties: {
          protocol: 'Https'
          path: healthProbePath
          interval: healthProbeInterval
          timeout: healthProbeTimeout
          unhealthyThreshold: healthProbeUnhealthyThreshold
          pickHostNameFromBackendHttpSettings: pickHostNameFromBackendSettings
          minServers: healthProbeMinServers
          match: {
            statusCodes: healthProbeStatusCodes
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
