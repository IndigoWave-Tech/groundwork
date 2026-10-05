// Platform Key Vault for secrets that other blueprints need
// (alert webhooks, automation credentials, certificates).
//
// Access is RBAC, not access policies. Network access is denied by default
// except for Azure trusted services and any IP ranges supplied.

targetScope = 'resourceGroup'

@description('Vault name, computed in main.bicep so Bicep and Terraform agree.')
param keyVaultName string

@description('Azure region.')
param location string

@description('Public IP ranges (CIDR) allowed through the firewall. Empty allows none beyond trusted Azure services.')
param allowedIpRanges array

@description('Resource ID of the Log Analytics workspace for audit events.')
param workspaceId string

@description('Tags for the vault.')
param tags object

resource keyVault 'Microsoft.KeyVault/vaults@2024-11-01' = {
  // checkov:skip=CKV_AZURE_189: Public endpoint behind a default-deny firewall by design; see README design decisions, Key Vault network access
  // checkov:skip=CKV2_AZURE_32: No private endpoint until a connected network exists; see README design decisions, Key Vault network access
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

// 2021-05-01-preview is the newest API version for diagnostic settings. The linter flags it as older than
// two years and offers only 2016-09-01, which predates the current schema; nothing newer exists to move to.
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
