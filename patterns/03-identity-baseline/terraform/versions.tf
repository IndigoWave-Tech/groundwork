terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # State must never live in this repository. See Pattern 01 for the
  # backend block to copy, with key "groundwork/03-identity-baseline.tfstate".
  # This state contains tenant and group object IDs; protect it accordingly.
}

# Microsoft Entra ID (tenant-level). Uses your Azure CLI login.
# Required Graph permissions on the deploying identity: Policy.ReadWrite.ConditionalAccess,
# Policy.Read.All, Group.ReadWrite.All, Application.Read.All. The Conditional Access
# Administrator and Groups Administrator roles together satisfy this for a user.
provider "azuread" {}

# Only used to send Entra sign-in and audit logs to the Pattern 01 workspace.
provider "azurerm" {
  features {}
}
