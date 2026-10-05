// Sends the subscription activity log (who did what, when) to Log Analytics.
// Activity log ingestion is free; without this, the history is lost after 90 days.

targetScope = 'subscription'

@description('Resource ID of the Log Analytics workspace that receives the activity log.')
param workspaceId string

// Subscription-scope diagnostic settings need 2017-05-01-preview or later, and 2021-05-01-preview is the
// newest version. The linter flags it as older than two years and offers only 2016-09-01, which cannot
// target a subscription; nothing newer exists to move to.
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
