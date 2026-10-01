// Sends the subscription activity log (who did what, when) to Log Analytics.
// Activity log ingestion is free; without this, the history is lost after 90 days.

targetScope = 'subscription'

param workspaceId string

// 2021-05-01-preview is the current diagnostic settings API; the only GA version (2016-09-01) lacks categoryGroup support.
#disable-next-line use-recent-api-versions
resource activityLog 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'send-activity-log-to-workspace'
  properties: {
    workspaceId: workspaceId
    logs: [
      { category: 'Administrative', enabled: true }
      { category: 'Security', enabled: true }
      { category: 'ServiceHealth', enabled: true }
      { category: 'Alert', enabled: true }
      { category: 'Recommendation', enabled: true }
      { category: 'Policy', enabled: true }
      { category: 'Autoscale', enabled: true }
      { category: 'ResourceHealth', enabled: true }
    ]
  }
}
