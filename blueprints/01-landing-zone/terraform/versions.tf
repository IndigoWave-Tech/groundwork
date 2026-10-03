terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      # 4.35 or later: the provider can take the subscription from the Azure CLI
      # login. Export ARM_SUBSCRIPTION_ID to make the choice explicit (see README).
      source  = "hashicorp/azurerm"
      version = "~> 4.35"
    }
  }

  # State holds resource IDs and must never live in this repository.
  # Uncomment and point at a storage account created outside this blueprint,
  # or pass these values with `terraform init -backend-config=...`.
  #
  # backend "azurerm" {
  #   resource_group_name  = "rg-tfstate"
  #   storage_account_name = "sttfstate<unique>"
  #   container_name       = "tfstate"
  #   key                  = "groundwork/01-landing-zone.tfstate"
  #   use_azuread_auth     = true
  # }
}

provider "azurerm" {
  features {
    key_vault {
      # Purge protection is on, so a destroy soft-deletes the vault rather
      # than removing it. Never purge on destroy; recover a soft-deleted vault
      # on redeploy instead of failing on the name.
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      # Fail destroy if a resource group still contains something this
      # configuration does not manage. Protects against silent data loss.
      prevent_deletion_if_contains_resources = true
    }
  }
}
