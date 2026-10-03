# =============================================================================
# Groundwork Blueprint 02: Overnight Watch (Terraform)
# Mirrors ../bicep/main.bicep. See ../README.md for the full guide.
# =============================================================================

data "azurerm_subscription" "current" {}

resource "azurerm_resource_group" "monitoring" {
  name     = "rg-platform-monitoring-${local.suffix}"
  location = var.location
  tags     = local.tags
}

# ----------------------------------------------------------------------------
# 1. Action groups
# ----------------------------------------------------------------------------

resource "azurerm_monitor_action_group" "critical" {
  name                = "ag-critical-${local.suffix}"
  resource_group_name = azurerm_resource_group.monitoring.name
  short_name          = "critical"
  tags                = local.tags

  dynamic "email_receiver" {
    for_each = { for i, e in var.critical_emails : i => e }
    content {
      name                    = "email-${email_receiver.key}"
      email_address           = email_receiver.value
      use_common_alert_schema = true
    }
  }

  dynamic "sms_receiver" {
    for_each = { for i, s in var.critical_sms_receivers : i => s }
    content {
      name         = "sms-${sms_receiver.key}"
      country_code = sms_receiver.value.country_code
      phone_number = sms_receiver.value.phone_number
    }
  }
}

resource "azurerm_monitor_action_group" "warning" {
  name                = "ag-warning-${local.suffix}"
  resource_group_name = azurerm_resource_group.monitoring.name
  short_name          = "warning"
  tags                = local.tags

  dynamic "email_receiver" {
    for_each = { for i, e in var.warning_emails : i => e }
    content {
      name                    = "email-${email_receiver.key}"
      email_address           = email_receiver.value
      use_common_alert_schema = true
    }
  }
}

# ----------------------------------------------------------------------------
# 5. Maintenance window suppression (deployed disabled)
# ----------------------------------------------------------------------------

resource "azurerm_monitor_alert_processing_rule_suppression" "maintenance_window" {
  name                = "apr-maintenance-window-${local.suffix}"
  resource_group_name = azurerm_resource_group.monitoring.name
  scopes              = [local.subscription_id]
  enabled             = false
  description         = "Suppresses all alert notifications while enabled. Enable for planned maintenance, disable afterwards. Deployed disabled."
  tags                = local.tags
}

# ----------------------------------------------------------------------------
# 6. Overnight summary workbook
# ----------------------------------------------------------------------------

resource "azurerm_application_insights_workbook" "overnight_summary" {
  name                = local.workbook_name
  resource_group_name = azurerm_resource_group.monitoring.name
  location            = var.location
  display_name        = "Overnight Summary"
  description         = "Changes, alerts, machine health and log volume for the last 24 hours. Open this first every morning."
  source_id           = lower(var.workspace_resource_id)
  category            = "workbook"
  data_json           = file("${path.module}/../workbook/overnight-summary.json")
  tags                = local.tags
}
