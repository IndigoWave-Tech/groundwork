# =============================================================================
# Groundwork Blueprint 01: Secure Landing Zone (Terraform)
# Mirrors ../bicep/main.bicep. See ../README.md for the full guide.
# =============================================================================

data "azurerm_subscription" "current" {}
data "azurerm_client_config" "current" {}

# ----------------------------------------------------------------------------
# 1. Resource groups
# ----------------------------------------------------------------------------

resource "azurerm_resource_group" "platform" {
  for_each = local.rg_names

  name     = each.value
  location = var.location
  tags     = local.tags
}

# ----------------------------------------------------------------------------
# 2. Central logging
# ----------------------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "platform" {
  name                = "log-platform-${local.suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.platform["logging"].name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  daily_quota_gb      = var.log_daily_quota_gb
  tags                = local.tags

  # Reading logs requires RBAC on the workspace, not just on the resource that
  # wrote them. false maps directly to enableLogAccessUsingOnlyResourcePermissions: false.
  allow_resource_only_permissions = false
}

resource "azurerm_monitor_diagnostic_setting" "activity_log" {
  name                       = "send-activity-log-to-workspace"
  target_resource_id         = data.azurerm_subscription.current.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.platform.id

  dynamic "enabled_log" {
    for_each = [
      "Administrative", "Security", "ServiceHealth", "Alert",
      "Recommendation", "Policy", "Autoscale", "ResourceHealth",
    ]
    content {
      category = enabled_log.value
    }
  }
}

# ----------------------------------------------------------------------------
# 4. Hub network
# ----------------------------------------------------------------------------

resource "azurerm_network_security_group" "shared" {
  name                = "nsg-shared-${local.suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.platform["network"].name
  tags                = local.tags

  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Default deny. Add explicit allow rules above this priority."
  }
}

resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub-${local.suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.platform["network"].name
  address_space       = [var.hub_address_space]
  tags                = local.tags
}

resource "azurerm_subnet" "shared" {
  name                 = "snet-shared"
  resource_group_name  = azurerm_resource_group.platform["network"].name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.shared_subnet_prefix]

  private_endpoint_network_policies             = "Enabled"
  private_link_service_network_policies_enabled = true
}

resource "azurerm_subnet_network_security_group_association" "shared" {
  subnet_id                 = azurerm_subnet.shared.id
  network_security_group_id = azurerm_network_security_group.shared.id
}

resource "azurerm_monitor_diagnostic_setting" "nsg" {
  name                       = "send-to-workspace"
  target_resource_id         = azurerm_network_security_group.shared.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.platform.id

  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }
  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}

resource "azurerm_monitor_diagnostic_setting" "vnet" {
  name                       = "send-to-workspace"
  target_resource_id         = azurerm_virtual_network.hub.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.platform.id

  enabled_log {
    category = "VMProtectionAlerts"
  }
  enabled_metric {
    category = "AllMetrics"
  }
}

# ----------------------------------------------------------------------------
# 5. Platform Key Vault
# ----------------------------------------------------------------------------

resource "azurerm_key_vault" "platform" {
  #checkov:skip=CKV_AZURE_189: Public endpoint behind a default-deny firewall by design; see README design decisions, Key Vault network access
  #checkov:skip=CKV2_AZURE_32: No private endpoint until a connected network exists; see README design decisions, Key Vault network access
  name                = local.key_vault_name
  location            = var.location
  resource_group_name = azurerm_resource_group.platform["security"].name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  tags                = local.tags

  rbac_authorization_enabled      = true
  soft_delete_retention_days      = 90
  purge_protection_enabled        = true
  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = true
  public_network_access_enabled   = true

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = var.key_vault_allowed_ip_ranges
  }
}

resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  name                       = "send-to-workspace"
  target_resource_id         = azurerm_key_vault.platform.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.platform.id

  enabled_log {
    category = "AuditEvent"
  }
  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }
  enabled_metric {
    category = "AllMetrics"
  }
}

# ----------------------------------------------------------------------------
# 6. Defender for Cloud posture and security contact
# ----------------------------------------------------------------------------

# Checkov evaluates each pricing resource statically and cannot follow the
# enable_defender_plans switch, so every skip below names the design decision.
resource "azurerm_security_center_subscription_pricing" "cspm" {
  #checkov:skip=CKV_AZURE_19: Foundational CSPM is the free tier by design; see README design decisions, Defender for Cloud
  #checkov:skip=CKV_AZURE_84: Defender for Storage belongs to the blueprint that deploys storage; see README design decisions, Defender for Cloud
  #checkov:skip=CKV_AZURE_87: Defender for Key Vault is the key_vaults resource below, behind enable_defender_plans; see README design decisions, Defender for Cloud
  tier          = "Free"
  resource_type = "CloudPosture"
}

# Defender for Servers Plan 1 and Defender for Key Vault, paid plans that are
# off by default. Defender security alerts (Blueprint 02's security alert rule)
# are generated only when a paid plan is on. See README design decisions.
resource "azurerm_security_center_subscription_pricing" "servers" {
  #checkov:skip=CKV_AZURE_19: Standard only when enable_defender_plans is true; see README design decisions, Defender for Cloud
  #checkov:skip=CKV_AZURE_55: Standard only when enable_defender_plans is true; see README design decisions, Defender for Cloud
  #checkov:skip=CKV_AZURE_84: This resource is the Servers plan; Defender for Storage belongs to the blueprint that deploys storage
  #checkov:skip=CKV_AZURE_87: This resource is the Servers plan; Defender for Key Vault is the key_vaults resource below
  tier          = var.enable_defender_plans ? "Standard" : "Free"
  resource_type = "VirtualMachines"
  subplan       = var.enable_defender_plans ? "P1" : null
}

resource "azurerm_security_center_subscription_pricing" "key_vaults" {
  #checkov:skip=CKV_AZURE_19: Standard only when enable_defender_plans is true; see README design decisions, Defender for Cloud
  #checkov:skip=CKV_AZURE_84: This resource is the Key Vault plan; Defender for Storage belongs to the blueprint that deploys storage
  #checkov:skip=CKV_AZURE_87: Standard only when enable_defender_plans is true; see README design decisions, Defender for Cloud
  tier          = var.enable_defender_plans ? "Standard" : "Free"
  resource_type = "KeyVaults"
}

# The provider exposes on/off switches only; the Bicep path sets a Medium
# minimal severity and Owner notification. See README design decisions.
resource "azurerm_security_center_contact" "default" {
  name  = "default"
  email = var.security_contact_email
  phone = var.security_contact_phone

  alert_notifications = true
  alerts_to_admins    = true
}

# ----------------------------------------------------------------------------
# 7. Budget safety net
# ----------------------------------------------------------------------------

resource "azurerm_consumption_budget_subscription" "platform" {
  name            = "budget-subscription-${local.suffix}"
  subscription_id = data.azurerm_subscription.current.id
  amount          = var.monthly_budget_amount
  time_grain      = "Monthly"

  time_period {
    start_date = local.budget_start_date
  }

  notification {
    enabled        = true
    threshold      = 50
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = [var.security_contact_email]
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = [var.security_contact_email]
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    threshold_type = "Forecasted"
    contact_emails = [var.security_contact_email]
  }

  lifecycle {
    # The start date is computed at plan time; do not churn it on every apply.
    ignore_changes = [time_period]
  }
}
