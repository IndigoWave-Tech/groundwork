terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # State holds resource IDs and must never live in this repository.
  # Uncomment and point at a storage account created outside this pattern,
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
      # than removing it. Keep these false so destroy does not try to purge.
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
