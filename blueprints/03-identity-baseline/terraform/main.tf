# =============================================================================
# Groundwork Blueprint 03: Identity Baseline (Terraform)
# Exclusion groups, named locations, and Entra log export.
# Conditional Access policies are in conditional-access.tf.
# =============================================================================

data "azuread_client_config" "current" {}

# ----------------------------------------------------------------------------
# Exclusion groups
# Policies target groups, not individual users, so membership changes never
# require a policy change. Both groups are assigned (not dynamic) and have
# the deploying identity as owner so membership is auditable.
#
# Both groups are role-assignable. Membership of a role-assignable group can
# be changed only by Privileged Role Administrators, Global Administrators and
# the group's owners (here, the deploying identity), so a Groups Administrator
# or User Administrator cannot add an account that then bypasses every policy.
# The flag cannot be changed after creation, and the deploying identity needs
# Privileged Role Administrator to set it. See the guide's design decisions.
# ----------------------------------------------------------------------------

resource "azuread_group" "break_glass_exclusions" {
  display_name            = "${local.prefix} CA Exclusion - Break Glass"
  description             = "Emergency access accounts excluded from ALL Conditional Access policies. Membership must be exactly the break-glass accounts. Role-assignable: only Global and Privileged Role Administrators can change membership. Reviewed quarterly."
  security_enabled        = true
  mail_enabled            = false
  assignable_to_role      = true
  prevent_duplicate_names = true
  owners                  = [data.azuread_client_config.current.object_id]
  members                 = var.break_glass_account_object_ids
}

resource "azuread_group" "mfa_exclusions" {
  display_name            = "${local.prefix} CA Exclusion - MFA Exempt"
  description             = "Accounts that cannot perform MFA, excluded from MFA requirements only. They remain subject to the legacy authentication block. Every member needs a documented reason. Role-assignable: only Global and Privileged Role Administrators can change membership. Reviewed quarterly."
  security_enabled        = true
  mail_enabled            = false
  assignable_to_role      = true
  prevent_duplicate_names = true
  owners                  = [data.azuread_client_config.current.object_id]
  members                 = var.service_account_object_ids
}

# ----------------------------------------------------------------------------
# Named locations
# ----------------------------------------------------------------------------

resource "azuread_named_location" "trusted_offices" {
  count = local.has_trusted_ips ? 1 : 0

  display_name = "${local.prefix} Trusted Office Egress"

  ip {
    ip_ranges = var.trusted_ip_ranges
    trusted   = true
  }
}

resource "azuread_named_location" "allowed_countries" {
  count = local.has_country_allow ? 1 : 0

  display_name = "${local.prefix} Allowed Countries"

  country {
    countries_and_regions                 = var.allowed_countries
    include_unknown_countries_and_regions = false
  }
}

# ----------------------------------------------------------------------------
# Entra ID sign-in and audit logs to the Blueprint 01 workspace
# Without this, report-only policy results are only visible in the portal
# for 30 days (P1). With it, they are queryable and retained for 90.
# ----------------------------------------------------------------------------

resource "azurerm_monitor_aad_diagnostic_setting" "entra_to_workspace" {
  count = var.workspace_resource_id == null ? 0 : 1

  name                       = "send-entra-logs-to-workspace"
  log_analytics_workspace_id = var.workspace_resource_id

  dynamic "enabled_log" {
    for_each = [
      "SignInLogs",
      "AuditLogs",
      "NonInteractiveUserSignInLogs",
      "ServicePrincipalSignInLogs",
      "ManagedIdentitySignInLogs",
      "RiskyUsers",
      "UserRiskEvents",
      "RiskyServicePrincipals",
      "ServicePrincipalRiskEvents",
    ]
    content {
      category = enabled_log.value
    }
  }
}
