// Activity log alerts. These fire on events Azure itself records: platform
// incidents, resource health changes, and administrative operations.
// They cost nothing and need no agent, so they work on day one.
//
// Scope is the whole subscription. Location is always 'global' for this type.
//
// This resource type has no display name field, so the resource name carries
// the ow- prefix and the description carries "Overnight Watch:", which is what
// the notification email shows. Log query alerts, which do have a display
// name, use the "Overnight Watch: <what>" form directly.

targetScope = 'resourceGroup'

@description('Resource ID of the critical action group.')
param criticalActionGroupId string

@description('Resource ID of the warning action group.')
param warningActionGroupId string

@description('Region display names to watch, including Global.')
param serviceHealthRegions array

@description('Tags for the alert rules.')
param tags object

var subscriptionScope = [subscription().id]
var toCritical = { actionGroups: [{ actionGroupId: criticalActionGroupId }] }
var toWarning = { actionGroups: [{ actionGroupId: warningActionGroupId }] }

// ---- Platform health ----------------------------------------------------------

resource serviceIncident 'Microsoft.Insights/activityLogAlerts@2026-01-01' = {
  name: 'ow-service-health-incident'
  location: 'global'
  tags: tags
  properties: {
    description: 'Overnight Watch: Azure reports an active service incident or security advisory affecting a region you use.'
    enabled: true
    scopes: subscriptionScope
    condition: {
      allOf: [
        { field: 'category', equals: 'ServiceHealth' }
        {
          anyOf: [
            { field: 'properties.incidentType', equals: 'Incident' }
            { field: 'properties.incidentType', equals: 'Security' }
          ]
        }
        {
          field: 'properties.impactedServices[*].ImpactedRegions[*].RegionName'
          containsAny: serviceHealthRegions
        }
      ]
    }
    actions: toCritical
  }
}

resource serviceMaintenance 'Microsoft.Insights/activityLogAlerts@2026-01-01' = {
  name: 'ow-service-health-maintenance'
  location: 'global'
  tags: tags
  properties: {
    description: 'Overnight Watch: Azure has announced planned maintenance or a health advisory for a region you use.'
    enabled: true
    scopes: subscriptionScope
    condition: {
      allOf: [
        { field: 'category', equals: 'ServiceHealth' }
        {
          anyOf: [
            { field: 'properties.incidentType', equals: 'Maintenance' }
            { field: 'properties.incidentType', equals: 'ActionRequired' }
            { field: 'properties.incidentType', equals: 'Informational' }
          ]
        }
        {
          field: 'properties.impactedServices[*].ImpactedRegions[*].RegionName'
          containsAny: serviceHealthRegions
        }
      ]
    }
    actions: toWarning
  }
}

resource resourceUnavailable 'Microsoft.Insights/activityLogAlerts@2026-01-01' = {
  name: 'ow-resource-health-unavailable'
  location: 'global'
  tags: tags
  properties: {
    description: 'Overnight Watch: A resource in this subscription became Unavailable or Degraded according to Azure Resource Health.'
    enabled: true
    scopes: subscriptionScope
    condition: {
      allOf: [
        { field: 'category', equals: 'ResourceHealth' }
        {
          anyOf: [
            { field: 'properties.currentHealthStatus', equals: 'Unavailable' }
            { field: 'properties.currentHealthStatus', equals: 'Degraded' }
          ]
        }
        // Platform-initiated only. A deliberate stop or deallocate is user-initiated
        // and should not page anyone; see README design decisions.
        { field: 'properties.cause', equals: 'PlatformInitiated' }
      ]
    }
    actions: toCritical
  }
}

// ---- Risky administrative changes ---------------------------------------------
// Each of these is a legitimate action someone might take on purpose. The
// alert exists so that when it happens at 2 a.m., somebody knows.

resource resourceGroupDeleted 'Microsoft.Insights/activityLogAlerts@2026-01-01' = {
  name: 'ow-admin-resource-group-deleted'
  location: 'global'
  tags: tags
  properties: {
    description: 'Overnight Watch: A resource group was deleted. Everything inside it is gone.'
    enabled: true
    scopes: subscriptionScope
    condition: {
      allOf: [
        { field: 'category', equals: 'Administrative' }
        { field: 'operationName', equals: 'Microsoft.Resources/subscriptions/resourceGroups/delete' }
        { field: 'status', equals: 'Succeeded' }
      ]
    }
    actions: toCritical
  }
}

resource keyVaultDeleted 'Microsoft.Insights/activityLogAlerts@2026-01-01' = {
  name: 'ow-admin-key-vault-deleted'
  location: 'global'
  tags: tags
  properties: {
    description: 'Overnight Watch: A Key Vault was deleted. Soft delete protects the contents for 90 days, but this should never be a surprise.'
    enabled: true
    scopes: subscriptionScope
    condition: {
      allOf: [
        { field: 'category', equals: 'Administrative' }
        { field: 'operationName', equals: 'Microsoft.KeyVault/vaults/delete' }
        { field: 'status', equals: 'Succeeded' }
      ]
    }
    actions: toCritical
  }
}

resource roleAssignmentChanged 'Microsoft.Insights/activityLogAlerts@2026-01-01' = {
  name: 'ow-admin-role-assignment-changed'
  location: 'global'
  tags: tags
  properties: {
    description: 'Overnight Watch: Someone was granted or removed from a role. Permissions changed.'
    enabled: true
    scopes: subscriptionScope
    condition: {
      allOf: [
        { field: 'category', equals: 'Administrative' }
        {
          anyOf: [
            { field: 'operationName', equals: 'Microsoft.Authorization/roleAssignments/write' }
            { field: 'operationName', equals: 'Microsoft.Authorization/roleAssignments/delete' }
          ]
        }
        { field: 'status', equals: 'Succeeded' }
      ]
    }
    actions: toWarning
  }
}

resource policyAssignmentDeleted 'Microsoft.Insights/activityLogAlerts@2026-01-01' = {
  name: 'ow-admin-policy-assignment-deleted'
  location: 'global'
  tags: tags
  properties: {
    description: 'Overnight Watch: A policy assignment was deleted. A guardrail from the landing zone may have been removed.'
    enabled: true
    scopes: subscriptionScope
    condition: {
      allOf: [
        { field: 'category', equals: 'Administrative' }
        { field: 'operationName', equals: 'Microsoft.Authorization/policyAssignments/delete' }
        { field: 'status', equals: 'Succeeded' }
      ]
    }
    actions: toWarning
  }
}

resource nsgChanged 'Microsoft.Insights/activityLogAlerts@2026-01-01' = {
  name: 'ow-admin-nsg-changed'
  location: 'global'
  tags: tags
  properties: {
    description: 'Overnight Watch: A network security group or one of its rules was created, changed or deleted. The network boundary moved.'
    enabled: true
    scopes: subscriptionScope
    condition: {
      allOf: [
        { field: 'category', equals: 'Administrative' }
        {
          anyOf: [
            { field: 'operationName', equals: 'Microsoft.Network/networkSecurityGroups/write' }
            { field: 'operationName', equals: 'Microsoft.Network/networkSecurityGroups/delete' }
            { field: 'operationName', equals: 'Microsoft.Network/networkSecurityGroups/securityRules/write' }
            { field: 'operationName', equals: 'Microsoft.Network/networkSecurityGroups/securityRules/delete' }
          ]
        }
        { field: 'status', equals: 'Succeeded' }
      ]
    }
    actions: toWarning
  }
}

resource diagnosticsDeleted 'Microsoft.Insights/activityLogAlerts@2026-01-01' = {
  name: 'ow-admin-diagnostics-deleted'
  location: 'global'
  tags: tags
  properties: {
    description: 'Overnight Watch: A diagnostic setting was deleted. Something stopped sending logs to the workspace.'
    enabled: true
    scopes: subscriptionScope
    condition: {
      allOf: [
        { field: 'category', equals: 'Administrative' }
        { field: 'operationName', equals: 'Microsoft.Insights/diagnosticSettings/delete' }
        { field: 'status', equals: 'Succeeded' }
      ]
    }
    actions: toWarning
  }
}

resource securityAlert 'Microsoft.Insights/activityLogAlerts@2026-01-01' = {
  name: 'ow-defender-security-alert'
  location: 'global'
  tags: tags
  properties: {
    description: 'Overnight Watch: Microsoft Defender for Cloud raised a security alert in this subscription.'
    enabled: true
    scopes: subscriptionScope
    condition: {
      allOf: [
        { field: 'category', equals: 'Security' }
      ]
    }
    actions: toCritical
  }
}
