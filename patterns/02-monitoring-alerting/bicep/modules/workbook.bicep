// The Overnight Summary workbook: one screen that answers "what happened
// while nobody was watching". Content lives in ../../workbook/ so the same
// definition is used by Bicep and Terraform.

targetScope = 'resourceGroup'

param location string
param workspaceResourceId string
param tags object

// Workbook names must be GUIDs. Derive one deterministically so redeploys
// update the same workbook instead of creating duplicates.
var workbookName = guid(resourceGroup().id, 'overnight-summary')

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
    serializedData: loadTextContent('../../workbook/overnight-summary.json')
    version: '1.0'
  }
}

output workbookId string = workbook.id
