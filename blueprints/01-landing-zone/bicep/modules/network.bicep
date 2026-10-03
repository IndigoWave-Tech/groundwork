// Hub virtual network with one shared services subnet behind a
// default-deny network security group. Address space is reserved for a
// gateway and Bastion so they can be added later without re-addressing.

targetScope = 'resourceGroup'

@description('Hub virtual network name, vnet-hub-<suffix>.')
param vnetName string

@description('Network security group name, nsg-shared-<suffix>.')
param nsgName string

@description('Azure region.')
param location string

@description('Address space of the hub network (CIDR).')
param addressSpace string

@description('Address prefix of the shared services subnet (CIDR), inside the address space.')
param sharedSubnetPrefix string

@description('Resource ID of the Log Analytics workspace for diagnostics.')
param workspaceId string

@description('Tags for the network resources.')
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

// 2021-05-01-preview is the newest API version for diagnostic settings. The linter flags it as older than
// two years and offers only 2016-09-01, which predates the current schema; nothing newer exists to move to.
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

// Same reason as above: 2021-05-01-preview is the newest version; the linter's alternative is 2016-09-01.
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
