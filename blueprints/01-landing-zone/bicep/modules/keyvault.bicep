// Platform Key Vault for secrets that other blueprints need
// (alert webhooks, automation credentials, certificates).
//
// Access is RBAC, not access policies. Network access is denied by default
// except for Azure trusted services and any IP ranges supplied.

targetScope = 'resourceGroup'

param keyVaultName string
param location string
param allowedIpRanges array
param workspaceId string
param tags object

resource keyVault 'Microsoft.KeyVault/vaults@2024-11-01' = {
  // checkov:skip=CKV_AZURE_189: Public endpoint stays reachable behind a default-deny firewall; private endpoints need a connected network most small organizations do not have yet, see README design decisions
  // checkov:skip=CKV2_AZURE_32: Private endpoint deferred for the same reason; add when a hub-connected network or VPN exists
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      ipRules: [
        for range in allowedIpRanges: {
          value: range
        }
      ]
      virtualNetworkRules: []
    }
  }
}

// 2021-05-01-preview is the current diagnostic settings API; the only GA version (2016-09-01) lacks categoryGroup support.
#disable-next-line use-recent-api-versions
resource keyVaultDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'send-to-workspace'
  scope: keyVault
  properties: {
    workspaceId: workspaceId
    logs: [
      { category: 'AuditEvent', enabled: true }
      { category: 'AzurePolicyEvaluationDetails', enabled: true }
    ]
    metrics: [
      { category: 'AllMetrics', enabled: true }
    ]
  }
}

output keyVaultName string = keyVault.name
output keyVaultId string = keyVault.id
output keyVaultUri string = keyVault.properties.vaultUri
