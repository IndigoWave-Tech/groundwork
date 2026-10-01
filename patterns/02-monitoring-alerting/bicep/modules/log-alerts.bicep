// Log query alerts against the central workspace from Pattern 01.
// These watch workloads. They fire nothing until a workload exists and sends
// data, so they are safe to deploy on an empty subscription.
//
// Virtual machine queries assume the Azure Monitor Agent with VM Insights
// (Heartbeat and InsightsMetrics tables). Any VM onboarded to the workspace
// is covered automatically; no per-VM alert rules are needed.

targetScope = 'resourceGroup'

param location string
param workspaceResourceId string
param criticalActionGroupId string
param warningActionGroupId string
param heartbeatMissingMinutes int
param lowDiskFreePercent int
param tags object

// ---- Critical: a machine stopped reporting -------------------------------------

resource vmHeartbeat 'Microsoft.Insights/scheduledQueryRules@2026-03-01' = {
  name: 'ow-vm-heartbeat-missing'
  location: location
  tags: tags
  kind: 'LogAlert'
  properties: {
    displayName: 'Overnight Watch: virtual machine stopped reporting'
    description: 'A virtual machine that normally sends a heartbeat has not done so for ${heartbeatMissingMinutes} minutes. It is off, disconnected, or the agent has failed.'
    severity: 0
    enabled: true
    evaluationFrequency: 'PT5M'
    windowSize: 'PT30M'
    scopes: [workspaceResourceId]
    targetResourceTypes: ['Microsoft.OperationalInsights/workspaces']
    criteria: {
      allOf: [
        {
          query: '''
Heartbeat
| summarize LastHeartbeat = max(TimeGenerated) by Computer, _ResourceId
| where LastHeartbeat < ago(${heartbeatMissingMinutes}m)
'''
          timeAggregation: 'Count'
          dimensions: [
            { name: 'Computer', operator: 'Include', values: ['*'] }
          ]
          resourceIdColumn: '_ResourceId'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    autoMitigate: true
    checkWorkspaceAlertsStorageConfigured: false
    skipQueryValidation: false
    actions: {
      actionGroups: [criticalActionGroupId]
    }
  }
}

// ---- Warning: disk filling up ------------------------------------------------------

resource lowDisk 'Microsoft.Insights/scheduledQueryRules@2026-03-01' = {
  name: 'ow-vm-low-disk-space'
  location: location
  tags: tags
  kind: 'LogAlert'
  properties: {
    displayName: 'Overnight Watch: disk below ${lowDiskFreePercent} percent free'
    description: 'A logical disk on a monitored virtual machine has less than ${lowDiskFreePercent} percent free space. Full disks take services down.'
    severity: 2
    enabled: true
    evaluationFrequency: 'PT15M'
    windowSize: 'PT30M'
    scopes: [workspaceResourceId]
    targetResourceTypes: ['Microsoft.OperationalInsights/workspaces']
    criteria: {
      allOf: [
        {
          query: '''
InsightsMetrics
| where Namespace == "LogicalDisk" and Name == "FreeSpacePercentage"
| extend Disk = tostring(parse_json(Tags)["vm.azm.ms/mountId"])
| summarize FreePercent = min(Val) by Computer, Disk, _ResourceId
'''
          timeAggregation: 'Minimum'
          metricMeasureColumn: 'FreePercent'
          dimensions: [
            { name: 'Computer', operator: 'Include', values: ['*'] }
            { name: 'Disk', operator: 'Include', values: ['*'] }
          ]
          resourceIdColumn: '_ResourceId'
          operator: 'LessThan'
          threshold: lowDiskFreePercent
          failingPeriods: {
            numberOfEvaluationPeriods: 2
            minFailingPeriodsToAlert: 2
          }
        }
      ]
    }
    autoMitigate: true
    checkWorkspaceAlertsStorageConfigured: false
    skipQueryValidation: false
    actions: {
      actionGroups: [warningActionGroupId]
    }
  }
}

// ---- Warning: someone is hammering the Key Vault --------------------------------

resource keyVaultForbidden 'Microsoft.Insights/scheduledQueryRules@2026-03-01' = {
  name: 'ow-key-vault-access-denied'
  location: location
  tags: tags
  kind: 'LogAlert'
  properties: {
    displayName: 'Overnight Watch: repeated Key Vault access denials'
    description: 'More than 10 denied requests to a Key Vault in 15 minutes. Either a misconfigured application or someone probing.'
    severity: 2
    enabled: true
    evaluationFrequency: 'PT15M'
    windowSize: 'PT15M'
    scopes: [workspaceResourceId]
    targetResourceTypes: ['Microsoft.OperationalInsights/workspaces']
    criteria: {
      allOf: [
        {
          query: '''
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.KEYVAULT" and Category == "AuditEvent"
| where ResultSignature in ("Forbidden", "Unauthorized")
| summarize Denials = count() by Resource, CallerIPAddress, _ResourceId
'''
          timeAggregation: 'Total'
          metricMeasureColumn: 'Denials'
          dimensions: [
            { name: 'Resource', operator: 'Include', values: ['*'] }
            { name: 'CallerIPAddress', operator: 'Include', values: ['*'] }
          ]
          resourceIdColumn: '_ResourceId'
          operator: 'GreaterThan'
          threshold: 10
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    autoMitigate: true
    checkWorkspaceAlertsStorageConfigured: false
    skipQueryValidation: false
    actions: {
      actionGroups: [warningActionGroupId]
    }
  }
}

// ---- Warning: the workspace hit its daily cap ------------------------------------

resource ingestionCapped 'Microsoft.Insights/scheduledQueryRules@2026-03-01' = {
  name: 'ow-workspace-daily-cap-reached'
  location: location
  tags: tags
  kind: 'LogAlert'
  properties: {
    displayName: 'Overnight Watch: log ingestion stopped at the daily cap'
    description: 'The Log Analytics workspace reached its daily ingestion cap. Logs are being dropped until the cap resets. Either something is logging in a loop or the cap needs raising.'
    severity: 1
    enabled: true
    evaluationFrequency: 'PT30M'
    windowSize: 'PT1H'
    scopes: [workspaceResourceId]
    targetResourceTypes: ['Microsoft.OperationalInsights/workspaces']
    criteria: {
      allOf: [
        {
          query: '''
_LogOperation
| where Category == "Ingestion" and Operation has "Data collection"
| where Level == "Warning"
'''
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    autoMitigate: true
    checkWorkspaceAlertsStorageConfigured: false
    skipQueryValidation: false
    actions: {
      actionGroups: [warningActionGroupId]
    }
  }
}

// ---- Warning: a VM stopped sending heartbeats entirely (silence vs. gap) ----------
// Note: the heartbeat rule above catches gaps. This companion rule catches the
// case where no heartbeat has arrived from any machine, which usually means
// the workspace or agent configuration broke, not a single VM.

resource noHeartbeats 'Microsoft.Insights/scheduledQueryRules@2026-03-01' = {
  name: 'ow-workspace-no-heartbeats'
  location: location
  tags: tags
  kind: 'LogAlert'
  properties: {
    displayName: 'Overnight Watch: all heartbeats stopped'
    description: 'Machines that reported in the last 24 hours have all gone silent for 30 minutes. Suspect the workspace, agent configuration, or a network change rather than individual machines.'
    severity: 1
    enabled: true
    evaluationFrequency: 'PT15M'
    windowSize: 'P1D'
    scopes: [workspaceResourceId]
    targetResourceTypes: ['Microsoft.OperationalInsights/workspaces']
    criteria: {
      allOf: [
        {
          query: '''
let recent = Heartbeat | where TimeGenerated > ago(30m) | summarize Recent = dcount(Computer);
let daily  = Heartbeat | where TimeGenerated > ago(1d)  | summarize Daily  = dcount(Computer);
recent | extend k = 1 | join kind=inner (daily | extend k = 1) on k
| where Daily > 0 and Recent == 0
| project Silent = Daily
'''
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    autoMitigate: true
    checkWorkspaceAlertsStorageConfigured: false
    skipQueryValidation: false
    actions: {
      actionGroups: [criticalActionGroupId]
    }
  }
}
