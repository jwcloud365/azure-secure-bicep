/*
  Monitoring Module
  
  This module creates monitoring // Reference the App Service resource
resource appService 'Microsoft.Web/sites@2021-02-01' existing = {
  name: split(appServiceId, '/')[8]
}

// Diagnostic Settings for App Service
resource appServiceDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${prefix}-${environment}-appservice-diag'
  scope: appService
  properties: {rces for the infrastructure:
  - Log Analytics Workspace
  - Application Insights
  - Diagnostic settings for key resources
*/

// ------------- Parameters -------------
@description('The Azure region for all resources')
param location string

@description('Resource name prefix')
param prefix string

@description('Environment name (dev, test, prod)')
param environment string

@description('The resource ID of the App Service')
param appServiceId string

@description('The resource ID of the SQL Server')
param sqlServerId string

@description('The resource ID of the WAF')
param wafId string

@description('Tags to apply to resources')
param tags object = {}

// ------------- Variables -------------
var logAnalyticsWorkspaceName = '${prefix}-${environment}-law'
var appInsightsName = '${prefix}-${environment}-ai'

// ------------- Resources -------------

// Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Application Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

// Reference the App Service resource
resource appServiceResource 'Microsoft.Web/sites@2021-02-01' existing = {
  name: split(appServiceId, '/')[8]
}

// Diagnostic Settings for App Service
resource appServiceDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${prefix}-${environment}-appservice-diag'
  scope: appServiceResource
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
      }
      {
        category: 'AppServiceAppLogs'
        enabled: true
      }
      {
        category: 'AppServiceAuditLogs'
        enabled: true
      }
      {
        category: 'AppServiceIPSecAuditLogs'
        enabled: true
      }
      {
        category: 'AppServicePlatformLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// Reference the SQL Server resource
resource sqlServer 'Microsoft.Sql/servers@2021-05-01-preview' existing = {
  name: split(sqlServerId, '/')[8]
}

// Diagnostic Settings for SQL Server
resource sqlServerDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${prefix}-${environment}-sqlserver-diag'
  scope: sqlServer
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'SQLSecurityAuditEvents'
        enabled: true
      }
      {
        category: 'DevOpsOperationsAudit'
        enabled: true
      }
    ]
  }
}

// Reference the WAF resource
resource waf 'Microsoft.Network/applicationGateways@2021-05-01' existing = {
  name: split(wafId, '/')[8]
}

// Diagnostic Settings for WAF
resource wafDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${prefix}-${environment}-waf-diag'
  scope: waf
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'ApplicationGatewayAccessLog'
        enabled: true
      }
      {
        category: 'ApplicationGatewayPerformanceLog'
        enabled: true
      }
      {
        category: 'ApplicationGatewayFirewallLog'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// ------------- Outputs -------------
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
output appInsightsId string = appInsights.id
output appInsightsConnectionString string = appInsights.properties.ConnectionString
