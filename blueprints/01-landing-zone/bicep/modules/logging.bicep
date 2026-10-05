// Central Log Analytics workspace. Every other resource in the landing zone
// sends its diagnostics here, so there is one place to look.

targetScope = 'resourceGroup'

@description('Workspace name, log-platform-<suffix>.')
param workspaceName string

@description('Azure region.')
param location string

@description('Interactive retention in days.')
param retentionDays int

@description('Daily ingestion cap in GB.')
param dailyQuotaGb int

@description('Tags for the workspace.')
param tags object

resource workspace 'Microsoft.OperationalInsights/workspaces@2026-03-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      // Pay-as-you-go. Commitment tiers only pay off above ~100 GB/day,
      // far beyond a typical small organization.
      name: 'PerGB2018'
    }
    retentionInDays: retentionDays
    features: {
      // Resources write to the workspace, but reading requires RBAC on the
      // workspace itself, not just the resource. Safer default.
      enableLogAccessUsingOnlyResourcePermissions: false
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    workspaceCapping: {
      // Daily ingestion cap in GB. Protects the bill if something starts
      // logging in a loop. Raise it deliberately if you outgrow it.
      dailyQuotaGb: dailyQuotaGb
    }
  }
}

output workspaceId string = workspace.id
output workspaceName string = workspace.name
