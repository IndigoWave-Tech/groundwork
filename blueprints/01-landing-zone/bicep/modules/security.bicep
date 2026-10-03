// Microsoft Defender for Cloud: foundational posture (free tier), a security
// contact so alerts reach a person, and two optional paid plans.
//
// Defender security alerts are generated only by paid plans. With
// enableDefenderPlans off (the default) the contact receives no alerts and
// Blueprint 02's Defender alert rule stays dormant. See the design decisions
// and the cost breakdown in ../../README.md before turning the plans on.
//
// Checkov evaluates each pricing resource statically and cannot follow the
// enableDefenderPlans switch, so every skip below names the design decision.

targetScope = 'subscription'

@description('Email address for the security contact.')
param securityContactEmail string

@description('Phone number for the security contact, in international format.')
param securityContactPhone string

@description('Enable Defender for Servers Plan 1 and Defender for Key Vault (paid). False keeps both at the free tier.')
param enableDefenderPlans bool

resource cspm 'Microsoft.Security/pricings@2024-01-01' = {
  // checkov:skip=CKV_AZURE_19: Foundational CSPM is the free tier by design; see README design decisions, Defender for Cloud
  // checkov:skip=CKV_AZURE_84: Defender for Storage belongs to the blueprint that deploys storage; see README design decisions, Defender for Cloud
  // checkov:skip=CKV_AZURE_87: Defender for Key Vault is the defenderKeyVault resource below, behind enableDefenderPlans; see README design decisions, Defender for Cloud
  name: 'CloudPosture'
  properties: {
    pricingTier: 'Free'
  }
}

// Defender for Servers Plan 1: endpoint detection and response for VMs, billed per server.
resource defenderServers 'Microsoft.Security/pricings@2024-01-01' = {
  // checkov:skip=CKV_AZURE_19: Standard only when enableDefenderPlans is true; see README design decisions, Defender for Cloud
  // checkov:skip=CKV_AZURE_84: This resource is the Servers plan; Defender for Storage belongs to the blueprint that deploys storage
  // checkov:skip=CKV_AZURE_87: This resource is the Servers plan; Defender for Key Vault is the defenderKeyVault resource below
  name: 'VirtualMachines'
  properties: {
    pricingTier: enableDefenderPlans ? 'Standard' : 'Free'
    subPlan: enableDefenderPlans ? 'P1' : null
  }
}

// Defender for Key Vault: anomaly detection on vault access, billed per transaction.
resource defenderKeyVault 'Microsoft.Security/pricings@2024-01-01' = {
  // checkov:skip=CKV_AZURE_19: Standard only when enableDefenderPlans is true; see README design decisions, Defender for Cloud
  // checkov:skip=CKV_AZURE_84: This resource is the Key Vault plan; Defender for Storage belongs to the blueprint that deploys storage
  // checkov:skip=CKV_AZURE_87: Standard only when enableDefenderPlans is true; see README design decisions, Defender for Cloud
  name: 'KeyVaults'
  properties: {
    pricingTier: enableDefenderPlans ? 'Standard' : 'Free'
  }
}

resource securityContact 'Microsoft.Security/securityContacts@2023-12-01-preview' = {
  // checkov:skip=CKV_AZURE_21: Check expects the retired 2017 API shape; alert emails for Medium and above are set via notificationsSources, see README security model
  // checkov:skip=CKV_AZURE_22: Check expects the retired 2017 API shape; subscription Owners are notified via notificationsByRole, see README security model
  name: 'default'
  properties: {
    emails: securityContactEmail
    phone: securityContactPhone
    isEnabled: true
    notificationsByRole: {
      state: 'On'
      roles: ['Owner']
    }
    notificationsSources: [
      {
        sourceType: 'Alert'
        minimalSeverity: 'Medium'
      }
    ]
  }
}
