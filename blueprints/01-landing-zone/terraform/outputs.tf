output "resource_group_names" {
  description = "Names of the platform resource groups."
  value       = local.rg_names
}

output "log_analytics_workspace_id" {
  description = "Resource ID of the central Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.platform.id
}

output "hub_vnet_id" {
  description = "Resource ID of the hub virtual network."
  value       = azurerm_virtual_network.hub.id
}

output "shared_subnet_id" {
  description = "Resource ID of the shared services subnet."
  value       = azurerm_subnet.shared.id
}

output "key_vault_name" {
  description = "Name of the platform Key Vault."
  value       = azurerm_key_vault.platform.name
}

output "key_vault_uri" {
  description = "URI of the platform Key Vault."
  value       = azurerm_key_vault.platform.vault_uri
}
