// Hub virtual network with one shared services subnet behind a
// default-deny network security group. Address space is reserved for a
// gateway and Bastion so they can be added later without re-addressing.

targetScope = 'resourceGroup'

param vnetName string
param nsgName string
param location string
param addressSpace string
param sharedSubnetPrefix string
param workspaceId string
param tags object

resource nsg 'Microsoft.Network/networkSecurityGroups@2025-09-01' = {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        // Azure's default rules already allow VNet-to-VNet and load balancer
        // traffic. This rule closes everything else inbound, including the
        // default "AllowInternetInBound" behaviour for public IPs.
        name: 'DenyAllInbound'
        properties: {
          priority: 4000
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          description: 'Default deny. Add explicit allow rules above this priority.'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2025-09-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [addressSpace]
    }
    subnets: [
      {
        name: 'snet-shared'
        properties: {
          addressPrefix: sharedSubnetPrefix
          networkSecurityGroup: {
            id: nsg.id
          }
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

// 2021-05-01-preview is the current diagnostic settings API; the only GA version (2016-09-01) lacks categoryGroup support.
#disable-next-line use-recent-api-versions
resource nsgDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'send-to-workspace'
  scope: nsg
  properties: {
    workspaceId: workspaceId
    logs: [
      { category: 'NetworkSecurityGroupEvent', enabled: true }
      { category: 'NetworkSecurityGroupRuleCounter', enabled: true }
    ]
  }
}

// 2021-05-01-preview is the current diagnostic settings API; the only GA version (2016-09-01) lacks categoryGroup support.
#disable-next-line use-recent-api-versions
resource vnetDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'send-to-workspace'
  scope: vnet
  properties: {
    workspaceId: workspaceId
    logs: [
      { category: 'VMProtectionAlerts', enabled: true }
    ]
    metrics: [
      { category: 'AllMetrics', enabled: true }
    ]
  }
}

output vnetId string = vnet.id
output sharedSubnetId string = vnet.properties.subnets[0].id
output nsgId string = nsg.id
