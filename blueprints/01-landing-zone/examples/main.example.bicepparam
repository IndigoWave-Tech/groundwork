// Example parameters for Blueprint 01: Secure Landing Zone.
// Copy to examples/main.local.bicepparam (ignored by git) and replace every value.

using '../bicep/main.bicep'

param orgCode = 'contoso'
param environment = 'prod'
param location = 'eastus2'
param allowedLocations = ['eastus2', 'centralus']

param tags = {
  owner: 'it@contoso.example'
  environment: 'prod'
  costCenter: 'IT-100'
}

param securityContactEmail = 'security@contoso.example'
param securityContactPhone = '+14045550100'
param monthlyBudgetAmount = 1500

param hubAddressSpace = '10.0.0.0/16'
param sharedSubnetPrefix = '10.0.1.0/24'

// Office egress IP ranges, if you want to reach the Key Vault from them directly,
// for example ['203.0.113.10/32']. Empty allows only trusted Azure services.
param keyVaultAllowedIpRanges = []

param logRetentionDays = 90
param logDailyQuotaGb = 5

// Paid Defender plans (Servers Plan 1, Key Vault). Off until there are servers to protect;
// Blueprint 02's Defender alert is live only when this is true. See the cost breakdown.
param enableDefenderPlans = false
