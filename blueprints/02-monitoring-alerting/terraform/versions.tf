terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # State must never live in this repository. See Blueprint 01 for the
  # backend block to copy, pointing at the same state storage account
  # with key "groundwork/02-overnight-watch.tfstate".
}

provider "azurerm" {
  features {}
}
