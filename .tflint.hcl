# TFLint configuration
# https://github.com/terraform-linters/tflint
#
# Cloud-specific rulesets (azurerm, aws, google) are added here,
# pinned to a version, as each blueprint that needs them is built.

config {
  call_module_type = "local"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# Azure rules for the Azure blueprints. Pinned; bump deliberately and let CI confirm.
plugin "azurerm" {
  enabled = true
  version = "0.32.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

# Every blueprint guide promises that `terraform destroy` tears the blueprint
# down, and a blueprint reaches Ready only after a sandbox deploy and teardown.
# A prevent_destroy lifecycle block would make that step fail until someone
# edits the code. Data-bearing resources are protected another way: Key Vault
# purge protection and 90-day soft delete, workspace soft delete, and
# prevent_deletion_if_contains_resources on resource groups. Each blueprint's
# design decisions table records the choice for its own resources.
rule "azurerm_resources_missing_prevent_destroy" {
  enabled = false
}
