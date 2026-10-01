// =============================================================================
// Groundwork Pattern 01: Secure Landing Zone
// Scope: a single Azure subscription
//
// Deploys the foundation every other Groundwork pattern builds on:
//   1. Resource groups for platform services
//   2. Central logging (Log Analytics) with the subscription activity log
//   3. Governance guardrails (Azure Policy)
//   4. A hub virtual network with a locked-down default subnet
//   5. A Key Vault for platform secrets
//   6. Microsoft Defender for Cloud foundational posture and a security contact
//   7. A subscription budget as a cost safety net
//
// Nothing in this file is environment-specific. All values come from the
// parameter file. See ../examples/main.example.bicepparam.
// =============================================================================

targetScope = 'subscription'

// ----------------------------------------------------------------------------
// Parameters
// ----------------------------------------------------------------------------

@description('Short, lowercase organization code used in resource names, for example "contoso". 2 to 8 characters.')
@minLength(2)
@maxLength(8)
param orgCode string

@description('Environment this subscription represents.')
@allowed(['prod', 'nonprod', 'sandbox'])
param environment string

@description('Primary Azure region for platform resources.')
param location string

@description('Regions where resources may be created. Policy denies everything else. Include the primary location.')
param allowedLocations array

@description('Tags applied to every resource group. Policy requires these three keys on all resource groups.')
param tags object = {
  owner: ''
  environment: ''
  costCenter: ''
}

@description('Email address that receives Defender for Cloud alerts and budget alerts.')
param securityContactEmail string

@description('Phone number for the security contact, in international format, for example +14045550100.')
param securityContactPhone string

@description('Monthly subscription budget in the billing currency. Alerts fire at 50, 80 and 100 percent of this amount.')
@minValue(1)
param monthlyBudgetAmount int

@description('Address space for the hub virtual network.')
param hubAddressSpace string = '10.0.0.0/16'

@description('Address prefix for the shared services subnet. Must sit inside hubAddressSpace.')
param sharedSubnetPrefix string = '10.0.1.0/24'

@description('Public IP ranges (CIDR) allowed to reach the Key Vault data plane, for example an office egress address. Leave empty to allow none; Azure trusted services are always allowed.')
param keyVaultAllowedIpRanges array = []

@description('Days to retain logs in Log Analytics. 90 days is the baseline for most small organizations.')
@minValue(30)
@maxValue(730)
param logRetentionDays int = 90

@description('Resource types that may never be created in this subscription. Defaults block classic (pre-ARM) resources.')
param deniedResourceTypes array = [
  'Microsoft.ClassicCompute/virtualMachines'
  'Microsoft.ClassicNetwork/virtualNetworks'
  'Microsoft.ClassicStorage/storageAccounts'
]

// ----------------------------------------------------------------------------
// Naming
// Convention: <type>-<org>-<workload>-<env>-<region short>
// ----------------------------------------------------------------------------

var regionShort = {
  eastus: 'eus'
  eastus2: 'eus2'
  centralus: 'cus'
  westus2: 'wus2'
  westus3: 'wus3'
  southcentralus: 'scus'
  northcentralus: 'ncus'
  canadacentral: 'cnc'
  northeurope: 'neu'
  westeurope: 'weu'
  uksouth: 'uks'
  australiaeast: 'aue'
}
var loc = regionShort[?location] ?? substring(location, 0, 4)
var suffix = '${orgCode}-${environment}-${loc}'

var rgNames = {
  logging: 'rg-platform-logging-${suffix}'
  network: 'rg-platform-network-${suffix}'
  security: 'rg-platform-security-${suffix}'
}

var deploymentTags = union(tags, {
  pattern: 'groundwork-01-landing-zone'
})

// ----------------------------------------------------------------------------
// 1. Resource groups
// ----------------------------------------------------------------------------

resource rgLogging 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: rgNames.logging
  location: location
  tags: deploymentTags
}

resource rgNetwork 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: rgNames.network
  location: location
  tags: deploymentTags
}

resource rgSecurity 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: rgNames.security
  location: location
  tags: deploymentTags
}

// ----------------------------------------------------------------------------
// 2. Central logging
// ----------------------------------------------------------------------------

module logging 'modules/logging.bicep' = {
  name: 'lz-logging'
  scope: rgLogging
  params: {
    workspaceName: 'log-platform-${suffix}'
    location: location
    retentionDays: logRetentionDays
    tags: deploymentTags
  }
}

module activityLog 'modules/activity-log.bicep' = {
  name: 'lz-activity-log'
  params: {
    workspaceId: logging.outputs.workspaceId
  }
}

// ----------------------------------------------------------------------------
// 3. Governance guardrails
// ----------------------------------------------------------------------------

module policy 'modules/policy.bicep' = {
  name: 'lz-policy'
  params: {
    location: location
    allowedLocations: allowedLocations
    requiredTagNames: ['owner', 'environment', 'costCenter']
    deniedResourceTypes: deniedResourceTypes
  }
}

// ----------------------------------------------------------------------------
// 4. Hub network
// ----------------------------------------------------------------------------

module network 'modules/network.bicep' = {
  name: 'lz-network'
  scope: rgNetwork
  params: {
    vnetName: 'vnet-hub-${suffix}'
    nsgName: 'nsg-shared-${suffix}'
    location: location
    addressSpace: hubAddressSpace
    sharedSubnetPrefix: sharedSubnetPrefix
    workspaceId: logging.outputs.workspaceId
    tags: deploymentTags
  }
}

// ----------------------------------------------------------------------------
// 5. Platform Key Vault
// ----------------------------------------------------------------------------

module keyVault 'modules/keyvault.bicep' = {
  name: 'lz-keyvault'
  scope: rgSecurity
  params: {
    // Key Vault names are globally unique, 3 to 24 chars, letters, digits and hyphens.
    keyVaultName: take('kv-${orgCode}-plat-${environment}-${uniqueString(subscription().subscriptionId)}', 24)
    location: location
    allowedIpRanges: keyVaultAllowedIpRanges
    workspaceId: logging.outputs.workspaceId
    tags: deploymentTags
  }
}

// ----------------------------------------------------------------------------
// 6. Defender for Cloud posture and security contact
// ----------------------------------------------------------------------------

module security 'modules/security.bicep' = {
  name: 'lz-security'
  params: {
    securityContactEmail: securityContactEmail
    securityContactPhone: securityContactPhone
  }
}

// ----------------------------------------------------------------------------
// 7. Budget safety net
// ----------------------------------------------------------------------------

module budget 'modules/budget.bicep' = {
  name: 'lz-budget'
  params: {
    budgetName: 'budget-subscription-${suffix}'
    amount: monthlyBudgetAmount
    contactEmails: [securityContactEmail]
  }
}

// ----------------------------------------------------------------------------
// Outputs
// ----------------------------------------------------------------------------

output resourceGroupNames object = rgNames
output logAnalyticsWorkspaceId string = logging.outputs.workspaceId
output hubVnetId string = network.outputs.vnetId
output sharedSubnetId string = network.outputs.sharedSubnetId
output keyVaultName string = keyVault.outputs.keyVaultName
output keyVaultUri string = keyVault.outputs.keyVaultUri
