# ----------------------------------------------------------------------------
# 4. Log query alerts: workload health
# Mirrors ../bicep/modules/log-alerts.bicep
# ----------------------------------------------------------------------------

locals {
  log_alerts = {
    # The window is 24 hours so a machine that reported at any point in the last
    # day and has now been silent for longer than the threshold keeps the alert
    # firing until it returns. See ../bicep/modules/log-alerts.bicep.
    vm-heartbeat-missing = {
      display_name         = "Overnight Watch: virtual machine stopped reporting"
      description          = "A virtual machine that reported in the last 24 hours has not sent a heartbeat for ${var.heartbeat_missing_minutes} minutes. It is off, disconnected, or the agent has failed."
      severity             = 0
      action               = "critical"
      evaluation_frequency = "PT5M"
      window_duration      = "P1D"
      query                = <<-KQL
        Heartbeat
        | where TimeGenerated > ago(1d)
        | summarize LastHeartbeat = max(TimeGenerated) by Computer, _ResourceId
        | where LastHeartbeat < ago(${var.heartbeat_missing_minutes}m)
      KQL
      time_aggregation     = "Count"
      metric_column        = null
      operator             = "GreaterThan"
      threshold            = 0
      dimensions           = ["Computer"]
      resource_id_column   = "_ResourceId"
      evaluation_periods   = 1
      min_failing_periods  = 1
    }
    vm-low-disk-space = {
      display_name         = "Overnight Watch: disk below ${var.low_disk_free_percent} percent free"
      description          = "A logical disk on a monitored virtual machine has less than ${var.low_disk_free_percent} percent free space. Full disks take services down."
      severity             = 2
      action               = "warning"
      evaluation_frequency = "PT15M"
      window_duration      = "PT30M"
      query                = <<-KQL
        InsightsMetrics
        | where Namespace == "LogicalDisk" and Name == "FreeSpacePercentage"
        | extend Disk = tostring(parse_json(Tags)["vm.azm.ms/mountId"])
        | summarize FreePercent = min(Val) by Computer, Disk, _ResourceId
      KQL
      time_aggregation     = "Minimum"
      metric_column        = "FreePercent"
      operator             = "LessThan"
      threshold            = var.low_disk_free_percent
      dimensions           = ["Computer", "Disk"]
      resource_id_column   = "_ResourceId"
      evaluation_periods   = 2
      min_failing_periods  = 2
    }
    key-vault-access-denied = {
      display_name         = "Overnight Watch: repeated Key Vault access denials"
      description          = "More than 10 denied requests to a Key Vault in 15 minutes. Either a misconfigured application or someone probing."
      severity             = 2
      action               = "warning"
      evaluation_frequency = "PT15M"
      window_duration      = "PT15M"
      query                = <<-KQL
        AzureDiagnostics
        | where ResourceProvider == "MICROSOFT.KEYVAULT" and Category == "AuditEvent"
        | where ResultSignature in ("Forbidden", "Unauthorized")
        | summarize Denials = count() by Resource, CallerIPAddress, _ResourceId
      KQL
      time_aggregation     = "Total"
      metric_column        = "Denials"
      operator             = "GreaterThan"
      threshold            = 10
      dimensions           = ["Resource", "CallerIPAddress"]
      resource_id_column   = "_ResourceId"
      evaluation_periods   = 1
      min_failing_periods  = 1
    }
    # Query shape follows the Microsoft Learn sample in "Monitor operational issues
    # in your Log Analytics workspace" (alert rules section).
    workspace-daily-cap-reached = {
      display_name         = "Overnight Watch: log ingestion stopped at the daily cap"
      description          = "The Log Analytics workspace reached its daily ingestion cap. Logs are being dropped until the cap resets. Either something is logging in a loop or the cap needs raising."
      severity             = 1
      action               = "warning"
      evaluation_frequency = "PT30M"
      window_duration      = "PT1H"
      query                = <<-KQL
        _LogOperation
        | where Category == "Ingestion" and Operation has "Data collection"
        | where Level == "Warning"
      KQL
      time_aggregation     = "Count"
      metric_column        = null
      operator             = "GreaterThan"
      threshold            = 0
      dimensions           = []
      resource_id_column   = null
      evaluation_periods   = 1
      min_failing_periods  = 1
    }
    workspace-no-heartbeats = {
      display_name         = "Overnight Watch: all heartbeats stopped"
      description          = "Machines that reported in the last 24 hours have all gone silent for 30 minutes. Suspect the workspace, agent configuration, or a network change rather than individual machines."
      severity             = 1
      action               = "critical"
      evaluation_frequency = "PT15M"
      window_duration      = "P1D"
      query                = <<-KQL
        let recent = Heartbeat | where TimeGenerated > ago(30m) | summarize Recent = dcount(Computer);
        let daily  = Heartbeat | where TimeGenerated > ago(1d)  | summarize Daily  = dcount(Computer);
        recent | extend k = 1 | join kind=inner (daily | extend k = 1) on k
        | where Daily > 0 and Recent == 0
        | project Silent = Daily
      KQL
      time_aggregation     = "Count"
      metric_column        = null
      operator             = "GreaterThan"
      threshold            = 0
      dimensions           = []
      resource_id_column   = null
      evaluation_periods   = 1
      min_failing_periods  = 1
    }
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "this" {
  for_each = local.log_alerts

  name                = "ow-${each.key}"
  resource_group_name = azurerm_resource_group.monitoring.name
  location            = var.location
  display_name        = each.value.display_name
  description         = each.value.description
  severity            = each.value.severity
  enabled             = true
  tags                = local.tags

  scopes                           = [var.workspace_resource_id]
  target_resource_types            = ["Microsoft.OperationalInsights/workspaces"]
  evaluation_frequency             = each.value.evaluation_frequency
  window_duration                  = each.value.window_duration
  auto_mitigation_enabled          = true
  workspace_alerts_storage_enabled = false
  skip_query_validation            = false

  criteria {
    query                   = each.value.query
    time_aggregation_method = each.value.time_aggregation
    metric_measure_column   = each.value.metric_column
    operator                = each.value.operator
    threshold               = each.value.threshold
    resource_id_column      = each.value.resource_id_column

    dynamic "dimension" {
      for_each = each.value.dimensions
      content {
        name     = dimension.value
        operator = "Include"
        values   = ["*"]
      }
    }

    failing_periods {
      number_of_evaluation_periods             = each.value.evaluation_periods
      minimum_failing_periods_to_trigger_alert = each.value.min_failing_periods
    }
  }

  action {
    action_groups = [local.action_group_ids[each.value.action]]
  }
}
