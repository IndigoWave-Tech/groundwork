// =============================================================================
// Groundwork Blueprint 01: Secure Landing Zone
// Scope: a single Azure subscription
//
// Deploys the foundation every other Groundwork blueprint builds on:
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

@description('Short organization code used in resource names, for example "contoso". 2 to 8 letters or digits; normalized to lowercase.')
@minLength(2)
@maxLength(8)
param orgCode string

@description('Environment this subscription represents.')
@allowed(['prod', 'nonprod', 'sandbox'])
param environment string

@description('Primary Azure region for platform resources.')
param location string

@description('Regions where resources may be created. Policy denies everything else. Include the primary location.')
@minLength(1)
param allowedLocations array

@description('Tags applied to every resource group: owner, environment and costCenter. Policy requires all three on every resource group, so there is no default.')
param tags object

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

@description('Daily ingestion cap for Log Analytics in GB. Protects the bill if something logs in a loop. Raise it deliberately if you outgrow it.')
@minValue(1)
param logDailyQuotaGb int = 5

@description('Resource types that may never be created in this subscription. Defaults block classic (pre-ARM) resources.')
param deniedResourceTypes array = [
  'Microsoft.ClassicCompute/virtualMachines'
  'Microsoft.ClassicNetwork/virtualNetworks'
  'Microsoft.ClassicStorage/storageAccounts'
]

@description('Enable the paid Defender for Servers Plan 1 and Defender for Key Vault plans. Off by default: the landing zone has no workloads to protect yet, and Defender security alerts (used by Blueprint 02) are generated only by paid plans. Read the cost breakdown before turning this on.')
param enableDefenderPlans bool = false

// ----------------------------------------------------------------------------
// Naming
// Convention: <type>-<workload>-<suffix>, where suffix = <org>-<env>-<region short>.
// Example: rg-platform-logging-contoso-prod-eus2. See docs/CONVENTIONS.md.
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
// Bicep cannot validate a regex, so the org code is normalized to lowercase here.
// The Terraform path rejects anything that is not 2 to 8 lowercase letters or digits.
var org = toLower(orgCode)
var suffix = '${org}-${environment}-${loc}'

// Key Vault names are globally unique, 3 to 24 characters, letters, digits and hyphens, no trailing hyphen.
// kv-<org>-<e>-<hash8>: org at most 8 characters, the environment as one letter, and the last 8 hex
// characters of the subscription ID. Longest possible name: 3 + 8 + 1 + 1 + 1 + 8 = 22 characters.
// Terraform derives the identical name (locals.tf), so both paths name the vault the same.
var envShort = { prod: 'p', nonprod: 'n', sandbox: 's' }
var subscriptionHash = substring(replace(subscription().subscriptionId, '-', ''), 24, 8)
var platformKeyVaultName = 'kv-${org}-${envShort[environment]}-${subscriptionHash}'

var rgNames = {
  logging: 'rg-platform-logging-${suffix}'
  network: 'rg-platform-network-${suffix}'
  security: 'rg-platform-security-${suffix}'
}

var deploymentTags = union(tags, {
  blueprint: 'groundwork-01-landing-zone'
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
    dailyQuotaGb: logDailyQuotaGb
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
    keyVaultName: platformKeyVaultName
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
    enableDefenderPlans: enableDefenderPlans
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

@description('Names of the three platform resource groups, keyed logging, network and security.')
output resourceGroupNames object = rgNames

@description('Resource ID of the central Log Analytics workspace. Blueprints 02, 03, 04 and 05 take this as workspaceResourceId.')
output logAnalyticsWorkspaceId string = logging.outputs.workspaceId

@description('Resource ID of the hub virtual network.')
output hubVnetId string = network.outputs.vnetId

@description('Resource ID of the shared services subnet.')
output sharedSubnetId string = network.outputs.sharedSubnetId

@description('Name of the platform Key Vault.')
output keyVaultName string = keyVault.outputs.keyVaultName

@description('URI of the platform Key Vault.')
output keyVaultUri string = keyVault.outputs.keyVaultUri
