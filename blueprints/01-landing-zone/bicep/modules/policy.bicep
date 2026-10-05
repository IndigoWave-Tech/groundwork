// Governance guardrails using built-in Azure Policy definitions.
// Deny effects stop a mistake before it exists. Modify fixes tags silently.
// Audit effects surface drift in the compliance dashboard without blocking.
//
// Definition IDs are Microsoft built-ins, verified against
// https://learn.microsoft.com/azure/governance/policy/samples/built-in-policies

targetScope = 'subscription'

@description('Region for the managed identities of the Modify assignments.')
param location string

@description('Regions where resources and resource groups may be created.')
param allowedLocations array

@description('Tag names required on resource groups and inherited to resources.')
param requiredTagNames array

@description('Resource types that may never be created.')
param deniedResourceTypes array

var builtIn = '/providers/Microsoft.Authorization/policyDefinitions'

var definitions = {
  allowedLocations: '${builtIn}/e56962a6-4747-49cd-b67b-bf8b01975c4c'
  allowedLocationsForResourceGroups: '${builtIn}/e765b5de-1225-4ba3-bd56-1ac6695af988'
  requireTagOnResourceGroups: '${builtIn}/96670d01-0a4d-4649-9c89-2d3abc0a5025'
  inheritTagFromResourceGroup: '${builtIn}/ea3f2387-9b95-492a-a190-fcdc54f7b070'
  notAllowedResourceTypes: '${builtIn}/6c112d4e-5bc7-47ae-a041-ea2d9dccd749'
  storageSecureTransfer: '${builtIn}/404c3081-a854-4457-ae30-26a93ef643f9'
  storageDisallowSharedKey: '${builtIn}/8c6a50c6-9ffd-4ae7-986f-5fa6111f9a54'
  keyVaultPurgeProtection: '${builtIn}/0b60c0b2-2dc2-4e1c-b5c9-abbed971de53'
  keyVaultRbacModel: '${builtIn}/12d4fa5e-1f9f-4c21-97a9-b99b3c6611b5'
  nicNoPublicIp: '${builtIn}/83a86a26-fd1f-447c-b59d-e51f44264114'
  subnetRequiresNsg: '${builtIn}/e71308d3-144b-4262-b144-efdc3cc90517'
  auditCustomRbacRoles: '${builtIn}/a451c1ef-c6ca-483d-87ed-f49761e3ffb5'
}

// Built-in role: Tag Contributor. Needed by the Modify assignments below.
var tagContributorRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4a9ae827-6dc8-4573-8ac7-8239d42aa03f')

// ---- Deny: regions -----------------------------------------------------------

resource allowedLocationsAssignment 'Microsoft.Authorization/policyAssignments@2026-07-01' = {
  name: 'lz-allowed-locations'
  properties: {
    displayName: 'Landing zone: allowed locations'
    description: 'Resources may only be created in the approved regions.'
    policyDefinitionId: definitions.allowedLocations
    enforcementMode: 'Default'
    parameters: {
      listOfAllowedLocations: { value: allowedLocations }
    }
  }
}

resource allowedRgLocationsAssignment 'Microsoft.Authorization/policyAssignments@2026-07-01' = {
  name: 'lz-allowed-rg-locations'
  properties: {
    displayName: 'Landing zone: allowed resource group locations'
    policyDefinitionId: definitions.allowedLocationsForResourceGroups
    enforcementMode: 'Default'
    parameters: {
      listOfAllowedLocations: { value: allowedLocations }
    }
  }
}

// ---- Deny: required tags on resource groups ----------------------------------

resource requireTagAssignments 'Microsoft.Authorization/policyAssignments@2026-07-01' = [
  for tagName in requiredTagNames: {
    name: 'lz-require-tag-${toLower(tagName)}'
    properties: {
      displayName: 'Landing zone: require "${tagName}" tag on resource groups'
      policyDefinitionId: definitions.requireTagOnResourceGroups
      enforcementMode: 'Default'
      parameters: {
        tagName: { value: tagName }
      }
    }
  }
]

// ---- Modify: inherit tags from the resource group ----------------------------

resource inheritTagAssignments 'Microsoft.Authorization/policyAssignments@2026-07-01' = [
  for tagName in requiredTagNames: {
    name: 'lz-inherit-tag-${toLower(tagName)}'
    location: location
    identity: {
      type: 'SystemAssigned'
    }
    properties: {
      displayName: 'Landing zone: inherit "${tagName}" tag from resource group'
      policyDefinitionId: definitions.inheritTagFromResourceGroup
      enforcementMode: 'Default'
      parameters: {
        tagName: { value: tagName }
      }
    }
  }
]

resource inheritTagRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for tagName in requiredTagNames: {
    name: guid(subscription().id, 'lz-inherit-tag', tagName, tagContributorRoleId)
    properties: {
      roleDefinitionId: tagContributorRoleId
      principalId: inheritTagAssignments[indexOf(requiredTagNames, tagName)].identity.principalId
      principalType: 'ServicePrincipal'
    }
  }
]

// ---- Deny: resource types that should never appear --------------------------

resource notAllowedTypesAssignment 'Microsoft.Authorization/policyAssignments@2026-07-01' = {
  name: 'lz-denied-resource-types'
  properties: {
    displayName: 'Landing zone: denied resource types'
    policyDefinitionId: definitions.notAllowedResourceTypes
    enforcementMode: 'Default'
    parameters: {
      listOfResourceTypesNotAllowed: { value: deniedResourceTypes }
    }
  }
}

// ---- Deny: insecure data-plane defaults --------------------------------------

resource storageSecureTransferAssignment 'Microsoft.Authorization/policyAssignments@2026-07-01' = {
  name: 'lz-storage-secure-transfer'
  properties: {
    displayName: 'Landing zone: storage accounts require HTTPS'
    policyDefinitionId: definitions.storageSecureTransfer
    enforcementMode: 'Default'
    parameters: {
      effect: { value: 'Deny' }
    }
  }
}

resource keyVaultPurgeProtectionAssignment 'Microsoft.Authorization/policyAssignments@2026-07-01' = {
  name: 'lz-kv-purge-protection'
  properties: {
    displayName: 'Landing zone: key vaults require purge protection'
    policyDefinitionId: definitions.keyVaultPurgeProtection
    enforcementMode: 'Default'
    parameters: {
      effect: { value: 'Deny' }
    }
  }
}

// ---- Audit: surface drift without blocking -----------------------------------
// These start as Audit so an existing environment can adopt the landing zone
// without breaking anything. Move to Deny once the compliance view is clean.

resource storageSharedKeyAssignment 'Microsoft.Authorization/policyAssignments@2026-07-01' = {
  name: 'lz-storage-no-shared-key'
  properties: {
    displayName: 'Landing zone: audit storage accounts allowing shared key access'
    policyDefinitionId: definitions.storageDisallowSharedKey
    enforcementMode: 'Default'
    parameters: {
      effect: { value: 'Audit' }
    }
  }
}

resource keyVaultRbacAssignment 'Microsoft.Authorization/policyAssignments@2026-07-01' = {
  name: 'lz-kv-rbac-model'
  properties: {
    displayName: 'Landing zone: audit key vaults not using RBAC'
    policyDefinitionId: definitions.keyVaultRbacModel
    enforcementMode: 'Default'
    parameters: {
      effect: { value: 'Audit' }
    }
  }
}

// This built-in has a fixed Deny effect and no effect parameter. It is assigned
// with enforcement off so it reports public-IP NICs in the compliance view
// without blocking them. Set enforcementMode to Default to turn it into a Deny.
resource nicNoPublicIpAssignment 'Microsoft.Authorization/policyAssignments@2026-07-01' = {
  name: 'lz-nic-no-public-ip'
  properties: {
    displayName: 'Landing zone: audit network interfaces with public IPs'
    description: 'Built-in Deny-only definition assigned in DoNotEnforce mode: it reports, it does not block. See README design decisions.'
    policyDefinitionId: definitions.nicNoPublicIp
    enforcementMode: 'DoNotEnforce'
  }
}

resource subnetNsgAssignment 'Microsoft.Authorization/policyAssignments@2026-07-01' = {
  name: 'lz-subnet-requires-nsg'
  properties: {
    displayName: 'Landing zone: audit subnets without a network security group'
    policyDefinitionId: definitions.subnetRequiresNsg
    enforcementMode: 'Default'
    parameters: {
      effect: { value: 'AuditIfNotExists' }
    }
  }
}

resource customRbacAssignment 'Microsoft.Authorization/policyAssignments@2026-07-01' = {
  name: 'lz-audit-custom-rbac'
  properties: {
    displayName: 'Landing zone: audit custom RBAC roles'
    policyDefinitionId: definitions.auditCustomRbacRoles
    enforcementMode: 'Default'
    parameters: {
      effect: { value: 'Audit' }
    }
  }
}
