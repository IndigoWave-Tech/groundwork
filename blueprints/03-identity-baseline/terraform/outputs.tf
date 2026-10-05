output "break_glass_exclusion_group_id" {
  description = "Object ID of the break-glass exclusion group. Its membership must be exactly the emergency access accounts."
  value       = azuread_group.break_glass_exclusions.object_id
}

output "mfa_exclusion_group_id" {
  description = "Object ID of the MFA-exempt group. Review its membership quarterly."
  value       = azuread_group.mfa_exclusions.object_id
}

output "policy_state" {
  description = "The state every policy was deployed in. Should read enabledForReportingButNotEnforced until the rollout procedure is complete."
  value       = var.policy_state
}

output "policy_ids" {
  description = "Conditional Access policy IDs by name."
  value = merge(
    {
      ca001_block_legacy_auth              = azuread_conditional_access_policy.ca001_block_legacy_auth.id
      ca101_mfa_all_users                  = azuread_conditional_access_policy.ca101_mfa_all_users.id
      ca102_mfa_guests                     = azuread_conditional_access_policy.ca102_mfa_guests.id
      ca103_mfa_security_info_registration = azuread_conditional_access_policy.ca103_mfa_security_info_registration.id
      ca201_mfa_admins                     = azuread_conditional_access_policy.ca201_mfa_admins.id
      ca202_mfa_azure_management           = azuread_conditional_access_policy.ca202_mfa_azure_management.id
      ca203_admin_session                  = azuread_conditional_access_policy.ca203_admin_session.id
      ca204_admin_browser_persistence      = azuread_conditional_access_policy.ca204_admin_browser_persistence.id
    },
    var.enable_risk_policies ? {
      ca301_sign_in_risk = azuread_conditional_access_policy.ca301_sign_in_risk[0].id
      ca302_user_risk    = azuread_conditional_access_policy.ca302_user_risk[0].id
    } : {},
    local.has_country_allow ? {
      ca401_block_countries = azuread_conditional_access_policy.ca401_block_countries[0].id
    } : {}
  )
}
