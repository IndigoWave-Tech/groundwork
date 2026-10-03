// The Overnight Summary workbook: one screen that answers "what happened
// while nobody was watching". Content lives in ../../workbook/ so the same
// definition is used by Bicep and Terraform.

targetScope = 'resourceGroup'

@description('Azure region.')
param location string

@description('Resource ID of the Log Analytics workspace the workbook queries.')
param workspaceResourceId string

@description('Minutes without a heartbeat before the workbook marks a machine Silent. Same value as the alert rule.')
param heartbeatMissingMinutes int

@description('Tags for the workbook.')
param tags object

// Workbook names must be GUIDs. Derive one deterministically so redeploys
// update the same workbook instead of creating duplicates.
var workbookName = guid(resourceGroup().id, 'overnight-summary')

// The JSON carries a placeholder for the heartbeat threshold so the workbook
// and the alert rule always agree. Terraform does the same replace.
var workbookJson = replace(loadTextContent('../../workbook/overnight-summary.json'), '__HEARTBEAT_MINUTES__', string(heartbeatMissingMinutes))

resource workbook 'Microsoft.Insights/workbooks@2023-06-01' = {
  name: workbookName
  location: location
  tags: tags
  kind: 'shared'
  properties: {
    displayName: 'Overnight Summary'
    description: 'Changes, alerts, machine health and log volume for the last 24 hours. Open this first every morning.'
    category: 'workbook'
    sourceId: workspaceResourceId
    serializedData: workbookJson
    version: '1.0'
  }
}

@description('Resource ID of the workbook.')
output workbookId string = workbook.id
