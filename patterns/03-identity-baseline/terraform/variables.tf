variable "org_code" {
  description = "Short, lowercase organization code used in names. Match Pattern 01."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{2,8}$", var.org_code))
    error_message = "org_code must be 2 to 8 lowercase letters or digits."
  }
}

variable "policy_state" {
  description = "State for every Conditional Access policy. Start with report-only, review the sign-in log impact for at least 7 days, then switch to enabled. See the guide's rollout procedure."
  type        = string
  default     = "enabledForReportingButNotEnforced"

  validation {
    condition     = contains(["enabledForReportingButNotEnforced", "enabled", "disabled"], var.policy_state)
    error_message = "policy_state must be enabledForReportingButNotEnforced, enabled, or disabled."
  }
}

variable "break_glass_account_object_ids" {
  description = "Object IDs of the emergency access (break-glass) accounts. These are excluded from every policy. Create them first; see the guide. At least two are required."
  type        = list(string)

  validation {
    condition     = length(var.break_glass_account_object_ids) >= 2
    error_message = "Provide at least two break-glass account object IDs. One is a single point of failure."
  }

  validation {
    condition     = alltrue([for id in var.break_glass_account_object_ids : can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", id))])
    error_message = "Each break-glass account must be an object ID (GUID), not a UPN."
  }
}

variable "service_account_object_ids" {
  description = "Object IDs of user accounts that cannot perform MFA (legacy service accounts, shared mailboxes with interactive sign-in). Excluded from MFA policies only, never from the legacy authentication block. Keep this list short and reviewed."
  type        = list(string)
  default     = []
}

variable "trusted_ip_ranges" {
  description = "Office or VPN egress IP ranges in CIDR form, marked as a trusted location. Used to relax MFA for Azure management from the office. Leave empty if you have no fixed egress IP."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for r in var.trusted_ip_ranges : can(cidrhost(r, 0))])
    error_message = "Each trusted IP range must be valid CIDR, for example 203.0.113.10/32."
  }
}

variable "allowed_countries" {
  description = "ISO 3166-1 alpha-2 country codes from which sign-ins are allowed, for example [\"US\", \"CA\"]. Sign-ins from anywhere else are blocked. Leave empty to skip the geographic block."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for c in var.allowed_countries : can(regex("^[A-Z]{2}$", c))])
    error_message = "Country codes must be two uppercase letters."
  }
}

variable "enable_risk_policies" {
  description = "Deploy the sign-in risk and user risk policies. Requires Microsoft Entra ID P2 (included in Microsoft 365 E5; NOT included in Business Premium, which has P1). On a P1 tenant the policies would be created but never trigger, so leave this false."
  type        = bool
  default     = false
}

variable "admin_sign_in_frequency_hours" {
  description = "How often administrators must re-authenticate to admin portals, in hours."
  type        = number
  default     = 4

  validation {
    condition     = var.admin_sign_in_frequency_hours >= 1 && var.admin_sign_in_frequency_hours <= 24
    error_message = "admin_sign_in_frequency_hours must be between 1 and 24."
  }
}

variable "workspace_resource_id" {
  description = "Resource ID of the Pattern 01 Log Analytics workspace. Entra sign-in and audit logs are sent there. Set to null to skip."
  type        = string
  default     = null
}
