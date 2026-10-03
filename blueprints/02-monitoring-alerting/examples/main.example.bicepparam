// Example parameters for Blueprint 02: Overnight Watch.
// Copy to main.local.bicepparam (ignored by git) and replace every value.
// Deploy Blueprint 01 first; this blueprint needs its workspace ID.

using '../bicep/main.bicep'

param orgCode = 'contoso'
param environment = 'prod'
param location = 'eastus2'

param tags = {
  owner: 'it@contoso.example'
  environment: 'prod'
  costCenter: 'IT-100'
}

// From Blueprint 01: az deployment sub show --name groundwork-lz --query properties.outputs.logAnalyticsWorkspaceId.value -o tsv
param workspaceResourceId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-platform-logging-contoso-prod-eus2/providers/Microsoft.OperationalInsights/workspaces/log-platform-contoso-prod-eus2'

// Critical: wakes someone up. Email plus SMS.
param criticalEmails = ['oncall@contoso.example']
param criticalSmsReceivers = [
  { countryCode: '1', phoneNumber: '4045550100' }
]

// Warning: reviewed in the morning.
param warningEmails = ['it@contoso.example']

// Display names, not region codes. Always include Global.
param serviceHealthRegions = ['East US 2', 'Central US', 'Global']

param heartbeatMissingMinutes = 10
param lowDiskFreePercent = 10
