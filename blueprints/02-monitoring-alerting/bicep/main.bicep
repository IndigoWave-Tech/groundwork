// =============================================================================
// Groundwork Blueprint 02: Overnight Watch
// Scope: a single Azure subscription, deployed after Blueprint 01
//
// Makes the environment tell someone when something is wrong:
//   1. Two action groups: critical (email + SMS) and warning (email)
//   2. Platform health alerts: Azure service incidents and resource health
//   3. Change alerts: risky administrative actions in the activity log
//   4. Workload health alerts: log queries against the central workspace
//   5. A pre-built but disabled maintenance window suppression rule
//   6. A workbook that summarises the night in one screen
//
// Nothing in this file is environment-specific. All values come from the
// parameter file. See ../examples/main.example.bicepparam.
// =============================================================================

targetScope = 'subscription'

// ----------------------------------------------------------------------------
// Parameters
// ----------------------------------------------------------------------------

@description('Short, lowercase organization code used in resource names. Match Blueprint 01.')
@minLength(2)
@maxLength(8)
param orgCode string

@description('Environment this subscription represents. Match Blueprint 01.')
@allowed(['prod', 'nonprod', 'sandbox'])
param environment string

@description('Primary Azure region. Match Blueprint 01.')
param location string

@description('Tags applied to every resource. Policy from Blueprint 01 requires owner, environment and costCenter.')
param tags object

@description('Resource ID of the Log Analytics workspace created by Blueprint 01 (output logAnalyticsWorkspaceId).')
param workspaceResourceId string

@description('Email addresses that receive critical alerts. These are the people who get woken up.')
@minLength(1)
param criticalEmails array

@description('SMS recipients for critical alerts. Each item: { countryCode: "1", phoneNumber: "4045550100" }. Leave empty to skip SMS.')
param criticalSmsReceivers array = []

@description('Email addresses that receive warning alerts. Reviewed in the morning, not at 2 a.m.')
@minLength(1)
param warningEmails array

@description('Azure region display names to watch for service incidents, for example ["East US 2", "Central US", "Global"]. Always include "Global".')
@minLength(1)
param serviceHealthRegions array

@description('Minutes without a heartbeat before a virtual machine is considered down.')
@minValue(5)
@maxValue(60)
param heartbeatMissingMinutes int = 10

@description('Percentage of free disk space below which a warning fires.')
@minValue(1)
@maxValue(50)
param lowDiskFreePercent int = 10

// ----------------------------------------------------------------------------
// Naming (same convention as Blueprint 01)
// ----------------------------------------------------------------------------

var regionShort = {
  eastus: 'eus'
  eastus2: 'eus2'
  centralus: 'cus'
  westus2: 'wus2'
  westus3: 'wus3'
  southcentralus: 'scus'
  northcentralus: 'ncus'
  canadacentral: 'cnc'
  northeurope: 'neu'
  westeurope: 'weu'
  uksouth: 'uks'
  australiaeast: 'aue'
}
var loc = regionShort[?location] ?? substring(location, 0, 4)
var suffix = '${orgCode}-${environment}-${loc}'

var deploymentTags = union(tags, {
  blueprint: 'groundwork-02-overnight-watch'
})

// ----------------------------------------------------------------------------
// Resource group
// ----------------------------------------------------------------------------

resource rgMonitoring 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: 'rg-platform-monitoring-${suffix}'
  location: location
  tags: deploymentTags
}

// ----------------------------------------------------------------------------
// 1. Action groups
// ----------------------------------------------------------------------------

module actionGroups 'modules/action-groups.bicep' = {
  name: 'ow-action-groups'
  scope: rgMonitoring
  params: {
    suffix: suffix
    criticalEmails: criticalEmails
    criticalSmsReceivers: criticalSmsReceivers
    warningEmails: warningEmails
    tags: deploymentTags
  }
}

// ----------------------------------------------------------------------------
// 2 and 3. Activity log alerts: platform health and risky changes
// ----------------------------------------------------------------------------

module activityAlerts 'modules/activity-alerts.bicep' = {
  name: 'ow-activity-alerts'
  scope: rgMonitoring
  params: {
    criticalActionGroupId: actionGroups.outputs.criticalActionGroupId
    warningActionGroupId: actionGroups.outputs.warningActionGroupId
    serviceHealthRegions: serviceHealthRegions
    tags: deploymentTags
  }
}

// ----------------------------------------------------------------------------
// 4. Log query alerts: workload health
// ----------------------------------------------------------------------------

module logAlerts 'modules/log-alerts.bicep' = {
  name: 'ow-log-alerts'
  scope: rgMonitoring
  params: {
    location: location
    workspaceResourceId: workspaceResourceId
    criticalActionGroupId: actionGroups.outputs.criticalActionGroupId
    warningActionGroupId: actionGroups.outputs.warningActionGroupId
    heartbeatMissingMinutes: heartbeatMissingMinutes
    lowDiskFreePercent: lowDiskFreePercent
    tags: deploymentTags
  }
}

// ----------------------------------------------------------------------------
// 5. Maintenance window suppression (disabled until needed)
// ----------------------------------------------------------------------------

module suppression 'modules/suppression.bicep' = {
  name: 'ow-suppression'
  scope: rgMonitoring
  params: {
    suffix: suffix
    tags: deploymentTags
  }
}

// ----------------------------------------------------------------------------
// 6. Overnight summary workbook
// ----------------------------------------------------------------------------

module workbook 'modules/workbook.bicep' = {
  name: 'ow-workbook'
  scope: rgMonitoring
  params: {
    location: location
    workspaceResourceId: workspaceResourceId
    tags: deploymentTags
  }
}

// ----------------------------------------------------------------------------
// Outputs
// ----------------------------------------------------------------------------

output resourceGroupName string = rgMonitoring.name
output criticalActionGroupId string = actionGroups.outputs.criticalActionGroupId
output warningActionGroupId string = actionGroups.outputs.warningActionGroupId
output workbookId string = workbook.outputs.workbookId
