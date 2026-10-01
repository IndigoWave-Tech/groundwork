# ----------------------------------------------------------------------------
# 2 and 3. Activity log alerts: platform health and risky changes
# Mirrors ../bicep/modules/activity-alerts.bicep
# ----------------------------------------------------------------------------

locals {
  activity_alerts = {
    service-health-incident = {
      description = "Azure reports an active service incident or security advisory affecting a region you use."
      severity    = "critical"
      category    = "ServiceHealth"
      service_health = {
        events    = ["Incident", "Security"]
        locations = var.service_health_regions
      }
    }
    service-health-maintenance = {
      description = "Azure has announced planned maintenance or a health advisory for a region you use."
      severity    = "warning"
      category    = "ServiceHealth"
      service_health = {
        events    = ["Maintenance", "ActionRequired", "Informational"]
        locations = var.service_health_regions
      }
    }
    resource-health-unavailable = {
      description = "A resource in this subscription became Unavailable or Degraded according to Azure Resource Health."
      severity    = "critical"
      category    = "ResourceHealth"
      resource_health = {
        current = ["Unavailable", "Degraded"]
        reason  = ["PlatformInitiated", "UserInitiated"]
      }
    }
    admin-resource-group-deleted = {
      description    = "A resource group was deleted. Everything inside it is gone."
      severity       = "critical"
      category       = "Administrative"
      operation_name = "Microsoft.Resources/subscriptions/resourceGroups/delete"
    }
    admin-key-vault-deleted = {
      description    = "A Key Vault was deleted. Soft delete protects the contents for 90 days, but this should never be a surprise."
      severity       = "critical"
      category       = "Administrative"
      operation_name = "Microsoft.KeyVault/vaults/delete"
    }
    admin-role-assignment-written = {
      description    = "Someone was granted a role. Permissions changed."
      severity       = "warning"
      category       = "Administrative"
      operation_name = "Microsoft.Authorization/roleAssignments/write"
    }
    admin-role-assignment-deleted = {
      description    = "Someone was removed from a role. Permissions changed."
      severity       = "warning"
      category       = "Administrative"
      operation_name = "Microsoft.Authorization/roleAssignments/delete"
    }
    admin-policy-assignment-deleted = {
      description    = "A policy assignment was deleted. A guardrail from the landing zone may have been removed."
      severity       = "warning"
      category       = "Administrative"
      operation_name = "Microsoft.Authorization/policyAssignments/delete"
    }
    admin-nsg-written = {
      description    = "A network security group was created or changed. The network boundary moved."
      severity       = "warning"
      category       = "Administrative"
      operation_name = "Microsoft.Network/networkSecurityGroups/write"
    }
    admin-nsg-deleted = {
      description    = "A network security group was deleted. The network boundary moved."
      severity       = "warning"
      category       = "Administrative"
      operation_name = "Microsoft.Network/networkSecurityGroups/delete"
    }
    admin-nsg-rule-written = {
      description    = "A network security group rule was created or changed. The network boundary moved."
      severity       = "warning"
      category       = "Administrative"
      operation_name = "Microsoft.Network/networkSecurityGroups/securityRules/write"
    }
    admin-nsg-rule-deleted = {
      description    = "A network security group rule was deleted. The network boundary moved."
      severity       = "warning"
      category       = "Administrative"
      operation_name = "Microsoft.Network/networkSecurityGroups/securityRules/delete"
    }
    admin-diagnostics-deleted = {
      description    = "A diagnostic setting was deleted. Something stopped sending logs to the workspace."
      severity       = "warning"
      category       = "Administrative"
      operation_name = "Microsoft.Insights/diagnosticSettings/delete"
    }
    defender-security-alert = {
      description = "Microsoft Defender for Cloud raised a security alert in this subscription."
      severity    = "critical"
      category    = "Security"
    }
  }

  action_group_ids = {
    critical = azurerm_monitor_action_group.critical.id
    warning  = azurerm_monitor_action_group.warning.id
  }
}

# The azurerm provider models one operation_name per alert, where Bicep
# allows anyOf. That is why NSG and role assignment alerts are split here;
# the coverage is identical.

resource "azurerm_monitor_activity_log_alert" "this" {
  for_each = local.activity_alerts

  name                = "ow-${each.key}"
  resource_group_name = azurerm_resource_group.monitoring.name
  location            = "global"
  scopes              = [local.subscription_id]
  description         = each.value.description
  enabled             = true
  tags                = local.tags

  criteria {
    category       = each.value.category
    operation_name = try(each.value.operation_name, null)
    status         = each.value.category == "Administrative" ? "Succeeded" : null

    dynamic "service_health" {
      for_each = try([each.value.service_health], [])
      content {
        events    = service_health.value.events
        locations = service_health.value.locations
      }
    }

    dynamic "resource_health" {
      for_each = try([each.value.resource_health], [])
      content {
        current = resource_health.value.current
        reason  = resource_health.value.reason
      }
    }
  }

  action {
    action_group_id = local.action_group_ids[each.value.severity]
  }
}
