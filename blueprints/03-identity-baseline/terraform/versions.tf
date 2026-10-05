terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
    azurerm = {
      # 4.35 or later: the provider can take the subscription from the Azure CLI
      # login when none is given below.
      source  = "hashicorp/azurerm"
      version = "~> 4.35"
    }
  }

  # State must never live in this repository. Uncomment and point at the same
  # storage account Blueprint 01 uses, or pass these values with
  # `terraform init -backend-config=...`. This state contains tenant and group
  # object IDs; protect it accordingly.
  #
  # backend "azurerm" {
  #   resource_group_name  = "rg-tfstate"
  #   storage_account_name = "sttfstate<unique>"
  #   container_name       = "tfstate"
  #   key                  = "groundwork/03-identity-baseline.tfstate"
  #   use_azuread_auth     = true
  # }
}

# Microsoft Entra ID (tenant-level). Uses your Azure CLI login.
# Graph permissions a service principal needs: Policy.ReadWrite.ConditionalAccess,
# Policy.Read.All, Group.ReadWrite.All and RoleManagement.ReadWrite.Directory (the
# last one for the role-assignable groups). For a user, the Conditional Access
# Administrator role plus Privileged Role Administrator covers this; the diagnostic
# setting below needs Global Administrator or Security Administrator in addition.
# See the guide's prerequisites.
provider "azuread" {}

# Only used to send Entra sign-in and audit logs to the Blueprint 01 workspace.
# azurerm 4.x needs a subscription context: taken from the workspace resource ID
# when log export is configured, otherwise from the CLI login (ARM_SUBSCRIPTION_ID
# or the CLI's default subscription). No Azure resource providers are registered
# here; Blueprint 01 already registered Microsoft.Insights.
provider "azurerm" {
  subscription_id                 = var.workspace_resource_id == null ? null : split("/", var.workspace_resource_id)[2]
  resource_provider_registrations = "none"
  features {}
}
