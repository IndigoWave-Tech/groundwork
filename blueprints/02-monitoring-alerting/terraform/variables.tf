variable "org_code" {
  description = "Short, lowercase organization code used in resource names. Match Blueprint 01."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{2,8}$", var.org_code))
    error_message = "org_code must be 2 to 8 lowercase letters or digits."
  }
}

variable "environment" {
  description = "Environment this subscription represents. Match Blueprint 01."
  type        = string

  validation {
    condition     = contains(["prod", "nonprod", "sandbox"], var.environment)
    error_message = "environment must be prod, nonprod, or sandbox."
  }
}

variable "location" {
  description = "Primary Azure region. Match Blueprint 01."
  type        = string
}

variable "tags" {
  description = "Tags applied to every resource. Policy from Blueprint 01 requires owner, environment and costCenter."
  type = object({
    owner       = string
    environment = string
    costCenter  = string
  })
}

variable "workspace_resource_id" {
  description = "Resource ID of the Log Analytics workspace created by Blueprint 01 (output log_analytics_workspace_id)."
  type        = string

  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.OperationalInsights/workspaces/[^/]+$", var.workspace_resource_id))
    error_message = "workspace_resource_id must be a full Log Analytics workspace resource ID."
  }
}

variable "critical_emails" {
  description = "Email addresses that receive critical alerts. These are the people who get woken up."
  type        = list(string)

  validation {
    condition     = length(var.critical_emails) > 0
    error_message = "At least one critical email is required."
  }
}

variable "critical_sms_receivers" {
  description = "SMS recipients for critical alerts. Leave empty to skip SMS."
  type = list(object({
    country_code = string
    phone_number = string
  }))
  default = []
}

variable "warning_emails" {
  description = "Email addresses that receive warning alerts. Reviewed in the morning, not at 2 a.m."
  type        = list(string)

  validation {
    condition     = length(var.warning_emails) > 0
    error_message = "At least one warning email is required."
  }
}

variable "service_health_regions" {
  description = "Azure region display names to watch for service incidents, for example [\"East US 2\", \"Central US\", \"Global\"]. Always include Global."
  type        = list(string)

  validation {
    condition     = contains(var.service_health_regions, "Global")
    error_message = "service_health_regions must include \"Global\"."
  }
}

variable "heartbeat_missing_minutes" {
  description = "Minutes without a heartbeat before a virtual machine is considered down."
  type        = number
  default     = 10

  validation {
    condition     = var.heartbeat_missing_minutes >= 5 && var.heartbeat_missing_minutes <= 60
    error_message = "heartbeat_missing_minutes must be between 5 and 60."
  }
}

variable "low_disk_free_percent" {
  description = "Percentage of free disk space below which a warning fires."
  type        = number
  default     = 10

  validation {
    condition     = var.low_disk_free_percent >= 1 && var.low_disk_free_percent <= 50
    error_message = "low_disk_free_percent must be between 1 and 50."
  }
}
