# ----------------------------------------------------------------------------
# Conditional Access policies
#
# Every policy is created in the state given by var.policy_state, which
# defaults to report-only. Report-only evaluates and logs the outcome without
# enforcing it. Review the impact in the sign-in logs, then flip to enabled.
#
# Naming: "CA<nnn> - <what it does>". Numbers group by purpose:
#   CA0xx  Block the worst things
#   CA1xx  Require MFA
#   CA2xx  Admin hardening
#   CA3xx  Risk-based (P2)
#   CA4xx  Location
# ----------------------------------------------------------------------------

# ---- CA001: Block legacy authentication ---------------------------------------
# Legacy protocols (IMAP, POP3, SMTP AUTH, older Office) cannot do MFA, so
# this is the hole attackers use to bypass everything else. Exclusion is
# break-glass only. If a device needs legacy auth, fix the device.

resource "azuread_conditional_access_policy" "ca001_block_legacy_auth" {
  display_name = "CA001 - Block legacy authentication"
  state        = var.policy_state

  conditions {
    client_app_types = ["exchangeActiveSync", "other"]

    applications {
      included_applications = ["All"]
    }

    users {
      included_users  = ["All"]
      excluded_groups = local.exclude_break_glass_only
    }
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["block"]
  }
}

# ---- CA101: Require MFA for all users -------------------------------------------

resource "azuread_conditional_access_policy" "ca101_mfa_all_users" {
  display_name = "CA101 - Require MFA for all users"
  state        = var.policy_state

  conditions {
    client_app_types = ["all"]

    applications {
      included_applications = ["All"]
    }

    users {
      included_users  = ["All"]
      excluded_groups = local.exclude_mfa
    }
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["mfa"]
  }
}

# ---- CA102: Require MFA for guests -------------------------------------------------
# Guests are covered by CA101 already. This policy exists so that guest MFA
# survives if CA101 is ever relaxed for internal users.

resource "azuread_conditional_access_policy" "ca102_mfa_guests" {
  display_name = "CA102 - Require MFA for guests and external users"
  state        = var.policy_state

  conditions {
    client_app_types = ["all"]

    applications {
      included_applications = ["All"]
    }

    users {
      included_guests_or_external_users {
        guest_or_external_user_types = ["b2bCollaborationGuest", "b2bCollaborationMember", "b2bDirectConnectUser", "otherExternalUser", "serviceProvider"]
        external_tenants {
          membership_kind = "all"
        }
      }
      excluded_groups = local.exclude_break_glass_only
    }
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["mfa"]
  }
}

# ---- CA103: Require MFA to register security info --------------------------------
# Stops an attacker with a stolen password from registering their own MFA
# method. Trusted office IPs are excluded so new-hire onboarding works.

resource "azuread_conditional_access_policy" "ca103_mfa_security_info_registration" {
  display_name = "CA103 - Require MFA to register security information"
  state        = var.policy_state

  conditions {
    client_app_types = ["all"]

    applications {
      included_user_actions = ["urn:user:registersecurityinfo"]
    }

    users {
      included_users  = ["All"]
      excluded_groups = local.exclude_mfa
      # Guests are excluded from this policy: in most configurations they register
      # security information in their home tenant, and those who do register here
      # are still held to MFA at sign-in by CA102. Excluding them avoids noise in
      # the report-only data.
      excluded_guests_or_external_users {
        guest_or_external_user_types = ["b2bCollaborationGuest", "b2bCollaborationMember", "b2bDirectConnectUser", "otherExternalUser", "serviceProvider"]
        external_tenants {
          membership_kind = "all"
        }
      }
    }

    locations {
      # "AllTrusted" is every location marked trusted in the tenant, not only the
      # one this blueprint creates. If other trusted locations exist, they relax
      # this policy too; review them before enabling. See the guide.
      included_locations = ["All"]
      excluded_locations = ["AllTrusted"]
    }
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["mfa"]
  }
}

# ---- CA201: Require MFA for administrators ---------------------------------------
# The 14 roles from Microsoft's template. Admins are excluded from nothing
# except break-glass; the MFA-exempt group does not apply here on purpose.

resource "azuread_conditional_access_policy" "ca201_mfa_admins" {
  display_name = "CA201 - Require MFA for administrators"
  state        = var.policy_state

  conditions {
    client_app_types = ["all"]

    applications {
      included_applications = ["All"]
    }

    users {
      included_roles  = local.admin_roles
      excluded_groups = local.exclude_break_glass_only
    }
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["mfa"]
  }
}

# ---- CA202: Require MFA for Azure management ---------------------------------------
# Azure portal, CLI, PowerShell, and anything else using the ARM API.

resource "azuread_conditional_access_policy" "ca202_mfa_azure_management" {
  display_name = "CA202 - Require MFA for Azure management"
  state        = var.policy_state

  conditions {
    client_app_types = ["all"]

    applications {
      included_applications = [local.app_windows_azure_service_management]
    }

    users {
      included_users  = ["All"]
      excluded_groups = local.exclude_mfa
    }
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["mfa"]
  }
}

# ---- CA203: Admin portal sign-in frequency ------------------------------------------
# Admin sessions to the admin portals and Azure management expire. A stolen
# admin session on a shared machine is worth much less if it dies in four
# hours. The sign-in frequency control can target specific apps; the
# persistent-browser control cannot, which is why it lives in CA204.

resource "azuread_conditional_access_policy" "ca203_admin_session" {
  display_name = "CA203 - Admin portals: periodic re-authentication"
  state        = var.policy_state

  conditions {
    client_app_types = ["browser", "mobileAppsAndDesktopClients"]

    applications {
      included_applications = [local.app_microsoft_admin_portals, local.app_windows_azure_service_management]
    }

    users {
      included_roles  = local.admin_roles
      excluded_groups = local.exclude_break_glass_only
    }
  }

  session_controls {
    sign_in_frequency        = var.admin_sign_in_frequency_hours
    sign_in_frequency_period = "hours"
  }
}

# ---- CA204: Admin browser sessions do not persist ----------------------------------
# Microsoft documents that the persistent browser session control requires the
# policy to target all resources ("All cloud apps"), so it cannot share CA203's
# app scope. Scoped to the admin roles so ordinary users keep "stay signed in".

resource "azuread_conditional_access_policy" "ca204_admin_browser_persistence" {
  display_name = "CA204 - Admin browser sessions do not persist"
  state        = var.policy_state

  conditions {
    client_app_types = ["all"]

    applications {
      included_applications = ["All"]
    }

    users {
      included_roles  = local.admin_roles
      excluded_groups = local.exclude_break_glass_only
    }
  }

  session_controls {
    persistent_browser_mode = "never"
  }
}

# ---- CA301 / CA302: Risk-based (Entra ID P2 only) ----------------------------------
# Session controls follow Microsoft's current templates for risk policies:
# re-authentication every time the risk condition is met, not on a timer.

resource "azuread_conditional_access_policy" "ca301_sign_in_risk" {
  count = var.enable_risk_policies ? 1 : 0

  display_name = "CA301 - Require MFA for medium and high sign-in risk"
  state        = var.policy_state

  conditions {
    client_app_types    = ["all"]
    sign_in_risk_levels = ["medium", "high"]

    applications {
      included_applications = ["All"]
    }

    users {
      included_users  = ["All"]
      excluded_groups = local.exclude_mfa
    }
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["mfa"]
  }

  session_controls {
    sign_in_frequency_interval = "everyTime"
  }
}

resource "azuread_conditional_access_policy" "ca302_user_risk" {
  count = var.enable_risk_policies ? 1 : 0

  display_name = "CA302 - Require password change for high user risk"
  state        = var.policy_state

  conditions {
    client_app_types = ["all"]
    user_risk_levels = ["high"]

    applications {
      included_applications = ["All"]
    }

    users {
      included_users  = ["All"]
      excluded_groups = local.exclude_mfa
    }
  }

  grant_controls {
    operator          = "AND"
    built_in_controls = ["mfa", "passwordChange"]
  }

  session_controls {
    sign_in_frequency_interval = "everyTime"
  }
}

# ---- CA401: Block sign-ins from outside allowed countries ----------------------------
# Only created when allowed_countries is set. Unknown locations are blocked
# too (include_unknown_countries_and_regions = false in the named location).

resource "azuread_conditional_access_policy" "ca401_block_countries" {
  count = local.has_country_allow ? 1 : 0

  display_name = "CA401 - Block sign-ins from outside allowed countries"
  state        = var.policy_state

  conditions {
    client_app_types = ["all"]

    applications {
      included_applications = ["All"]
    }

    users {
      included_users  = ["All"]
      excluded_groups = local.exclude_break_glass_only
    }

    locations {
      included_locations = ["All"]
      excluded_locations = [azuread_named_location.allowed_countries[0].id]
    }
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["block"]
  }
}
