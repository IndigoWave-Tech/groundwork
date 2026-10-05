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
