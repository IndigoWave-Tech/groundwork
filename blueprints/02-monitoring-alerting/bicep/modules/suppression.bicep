// A maintenance window suppression rule, deployed DISABLED.
//
// When you patch servers on a Saturday night, you do not want twenty pages.
// Enable this rule for the window, then disable it again. Having it ready
// means the person doing maintenance does not improvise at midnight.
//
// Scope is the subscription, so it suppresses everything. Narrow the scope
// to a resource group if only part of the estate is under maintenance.

targetScope = 'resourceGroup'

@description('Naming suffix, <org>-<env>-<regionShort>.')
param suffix string

@description('Tags for the rule.')
param tags object

resource maintenanceWindow 'Microsoft.AlertsManagement/actionRules@2021-08-08' = {
  name: 'apr-maintenance-window-${suffix}'
  location: 'global'
  tags: tags
  properties: {
    description: 'Suppresses all alert notifications while enabled. Enable for planned maintenance, disable afterwards. Deployed disabled.'
    enabled: false
    scopes: [subscription().id]
    actions: [
      {
        actionType: 'RemoveAllActionGroups'
      }
    ]
    // No schedule block: the rule applies whenever it is enabled. This keeps
    // the on/off switch simple. Add a schedule for recurring windows.
  }
}

output suppressionRuleId string = maintenanceWindow.id
