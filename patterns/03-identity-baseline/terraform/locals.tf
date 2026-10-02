locals {
  # Group and named-location display names carry the org code so they sort
  # together and are obviously managed by this pattern.
  prefix = "${upper(var.org_code)} Groundwork"

  # The 14 roles Microsoft's own "Require MFA for administrators" template
  # targets. Template IDs verified against the Microsoft Entra built-in roles
  # reference (learn.microsoft.com/entra/identity/role-based-access-control/permissions-reference).
  admin_role_template_ids = {
    global_administrator                    = "62e90394-69f5-4237-9190-012177145e10"
    application_administrator               = "9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3"
    authentication_administrator            = "c4e39bd9-1100-46d3-8c65-fb160da0071f"
    billing_administrator                   = "b0f54661-2d74-4c50-afa3-1ec803f12efe"
    cloud_application_administrator         = "158c047a-c907-4556-b7ef-446551a6b5f7"
    conditional_access_administrator        = "b1be1c3e-b65d-4f19-8427-f6fa0d97feb9"
    exchange_administrator                  = "29232cdf-9323-42fd-ade2-1d097af3e4de"
    helpdesk_administrator                  = "729827e3-9c14-49f7-bb1b-9608f156bbb8"
    password_administrator                  = "966707d0-3269-4727-9be2-8c3a10f19b9d"
    privileged_authentication_administrator = "7be44c8a-adaf-4e2a-84d6-ab2649e08a13"
    privileged_role_administrator           = "e8611ab8-c189-46e8-94e1-60213ab1f814"
    security_administrator                  = "194ae4cb-b126-40b2-bd5b-6091b380977d"
    sharepoint_administrator                = "f28a1f50-f6e7-4571-818b-6a12f2af6b6c"
    user_administrator                      = "fe930be7-5e62-47db-91af-98c3a49a38b1"
  }
  admin_roles = values(local.admin_role_template_ids)

  # Well-known first-party application IDs.
  app_windows_azure_service_management = "797f4846-ba00-4fd7-ba43-dac1f8f63013" # Azure portal, CLI, PowerShell
  app_microsoft_admin_portals          = "MicrosoftAdminPortals"                # Conditional Access built-in target

  # Every policy excludes the break-glass group. MFA policies also exclude
  # the service-account group. The legacy auth block excludes nothing but
  # break-glass, on purpose.
  exclude_break_glass_only = [azuread_group.break_glass_exclusions.object_id]
  exclude_mfa              = [azuread_group.break_glass_exclusions.object_id, azuread_group.mfa_exclusions.object_id]

  has_trusted_ips   = length(var.trusted_ip_ranges) > 0
  has_country_allow = length(var.allowed_countries) > 0
}
