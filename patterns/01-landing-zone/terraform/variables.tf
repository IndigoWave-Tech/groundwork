variable "org_code" {
  description = "Short, lowercase organization code used in resource names, for example \"contoso\". 2 to 8 characters."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{2,8}$", var.org_code))
    error_message = "org_code must be 2 to 8 lowercase letters or digits."
  }
}

variable "environment" {
  description = "Environment this subscription represents."
  type        = string

  validation {
    condition     = contains(["prod", "nonprod", "sandbox"], var.environment)
    error_message = "environment must be prod, nonprod, or sandbox."
  }
}

variable "location" {
  description = "Primary Azure region for platform resources."
  type        = string
}

variable "allowed_locations" {
  description = "Regions where resources may be created. Policy denies everything else. Include the primary location."
  type        = list(string)

  validation {
    condition     = length(var.allowed_locations) > 0
    error_message = "allowed_locations must contain at least one region."
  }
}

variable "tags" {
  description = "Tags applied to every resource group. Policy requires owner, environment and costCenter on all resource groups."
  type = object({
    owner       = string
    environment = string
    costCenter  = string
  })
}

variable "security_contact_email" {
  description = "Email address that receives Defender for Cloud alerts and budget alerts."
  type        = string

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.security_contact_email))
    error_message = "security_contact_email must be a valid email address."
  }
}

variable "security_contact_phone" {
  description = "Phone number for the security contact, in international format, for example +14045550100."
  type        = string
}

variable "monthly_budget_amount" {
  description = "Monthly subscription budget in the billing currency. Alerts fire at 50, 80 and 100 percent."
  type        = number

  validation {
    condition     = var.monthly_budget_amount >= 1
    error_message = "monthly_budget_amount must be at least 1."
  }
}

variable "hub_address_space" {
  description = "Address space for the hub virtual network."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.hub_address_space, 0))
    error_message = "hub_address_space must be a valid CIDR block."
  }
}

variable "shared_subnet_prefix" {
  description = "Address prefix for the shared services subnet. Must sit inside hub_address_space."
  type        = string
  default     = "10.0.1.0/24"
}

variable "key_vault_allowed_ip_ranges" {
  description = "Public IP ranges (CIDR) allowed to reach the Key Vault data plane. Azure trusted services are always allowed."
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "Days to retain logs in Log Analytics."
  type        = number
  default     = 90

  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "log_retention_days must be between 30 and 730."
  }
}

variable "log_daily_quota_gb" {
  description = "Daily ingestion cap for Log Analytics in GB. Protects the bill if something logs in a loop."
  type        = number
  default     = 5
}

variable "denied_resource_types" {
  description = "Resource types that may never be created in this subscription."
  type        = list(string)
  default = [
    "Microsoft.ClassicCompute/virtualMachines",
    "Microsoft.ClassicNetwork/virtualNetworks",
    "Microsoft.ClassicStorage/storageAccounts",
  ]
}
