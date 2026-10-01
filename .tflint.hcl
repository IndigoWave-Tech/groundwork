# TFLint configuration
# https://github.com/terraform-linters/tflint
#
# Cloud-specific rulesets (azurerm, aws, google) are added here,
# pinned to a version, as each pattern that needs them is built.

config {
  call_module_type = "local"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}
