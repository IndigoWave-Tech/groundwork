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
  # Uncomment and point at the same storage account Blueprint 01 uses,
  # or pass these values with `terraform init -backend-config=...`.
  #
  # backend "azurerm" {
  #   resource_group_name  = "rg-tfstate"
  #   storage_account_name = "sttfstate<unique>"
  #   container_name       = "tfstate"
  #   key                  = "groundwork/02-monitoring-alerting.tfstate"
  #   use_azuread_auth     = true
  # }
}

provider "azurerm" {
  features {
    resource_group {
      # Fail destroy if the monitoring resource group still contains something
      # this configuration does not manage. Same setting as Blueprint 01.
      prevent_deletion_if_contains_resources = true
    }
  }
}
