// Example parameters for Pattern 01: Secure Landing Zone.
// Copy to main.local.bicepparam (ignored by git) and replace every value.

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

// Office egress IP, if you want to reach the Key Vault from it directly.
param keyVaultAllowedIpRanges = []

param logRetentionDays = 90
