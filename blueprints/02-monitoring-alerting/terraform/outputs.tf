output "resource_group_name" {
  description = "Name of the monitoring resource group."
  value       = azurerm_resource_group.monitoring.name
}

output "critical_action_group_id" {
  description = "Resource ID of the critical action group. Reference it from other blueprints' alerts."
  value       = azurerm_monitor_action_group.critical.id
}

output "warning_action_group_id" {
  description = "Resource ID of the warning action group."
  value       = azurerm_monitor_action_group.warning.id
}

output "workbook_id" {
  description = "Resource ID of the Overnight Summary workbook."
  value       = azurerm_application_insights_workbook.overnight_summary.id
}

output "maintenance_suppression_rule_id" {
  description = "Resource ID of the disabled maintenance window suppression rule."
  value       = azurerm_monitor_alert_processing_rule_suppression.maintenance_window.id
}
