// Microsoft Defender for Cloud: foundational posture (free tier) and a
// security contact so alerts reach a person.
//
// Paid Defender plans are deliberately not enabled here. They are a
// per-workload decision with real monthly cost, made in the blueprint that
// introduces the workload. See the design decisions in ../../README.md.

targetScope = 'subscription'

param securityContactEmail string
param securityContactPhone string

resource cspm 'Microsoft.Security/pricings@2024-01-01' = {
  // checkov:skip=CKV_AZURE_19: Foundational CSPM is free; paid plans are a per-workload decision, see README design decisions
  // checkov:skip=CKV_AZURE_84: Defender for Storage is enabled by the blueprint that deploys storage, not the landing zone
  // checkov:skip=CKV_AZURE_87: Defender for Key Vault is a paid plan; decision deferred until the vault holds production secrets
  name: 'CloudPosture'
  properties: {
    pricingTier: 'Free'
  }
}

resource securityContact 'Microsoft.Security/securityContacts@2023-12-01-preview' = {
  // checkov:skip=CKV_AZURE_21: Check expects the retired 2017 API shape; email alerts for Medium and above are enabled via notificationsSources below
  // checkov:skip=CKV_AZURE_22: Check expects the retired 2017 API shape; subscription Owners are notified via notificationsByRole below
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
