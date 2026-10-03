# ----------------------------------------------------------------------------
# 3. Governance guardrails
# Built-in definitions only. IDs verified against the Microsoft Learn
# built-in policy reference; see ../README.md design decisions.
# ----------------------------------------------------------------------------

# ---- Deny: regions -----------------------------------------------------------

resource "azurerm_subscription_policy_assignment" "allowed_locations" {
  name                 = "lz-allowed-locations"
  display_name         = "Landing zone: allowed locations"
  description          = "Resources may only be created in the approved regions."
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = local.policy_definitions.allowed_locations

  parameters = jsonencode({
    listOfAllowedLocations = { value = var.allowed_locations }
  })
}

resource "azurerm_subscription_policy_assignment" "allowed_rg_locations" {
  name                 = "lz-allowed-rg-locations"
  display_name         = "Landing zone: allowed resource group locations"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = local.policy_definitions.allowed_locations_for_resource_groups

  parameters = jsonencode({
    listOfAllowedLocations = { value = var.allowed_locations }
  })
}

# ---- Deny: required tags on resource groups ----------------------------------

resource "azurerm_subscription_policy_assignment" "require_tag" {
  for_each = toset(local.required_tag_names)

  name                 = "lz-require-tag-${lower(each.value)}"
  display_name         = "Landing zone: require \"${each.value}\" tag on resource groups"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = local.policy_definitions.require_tag_on_resource_groups

  parameters = jsonencode({
    tagName = { value = each.value }
  })
}

# ---- Modify: inherit tags from the resource group ----------------------------

resource "azurerm_subscription_policy_assignment" "inherit_tag" {
  for_each = toset(local.required_tag_names)

  name                 = "lz-inherit-tag-${lower(each.value)}"
  display_name         = "Landing zone: inherit \"${each.value}\" tag from resource group"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = local.policy_definitions.inherit_tag_from_resource_group
  location             = var.location

  identity {
    type = "SystemAssigned"
  }

  parameters = jsonencode({
    tagName = { value = each.value }
  })
}

resource "azurerm_role_assignment" "inherit_tag" {
  for_each = azurerm_subscription_policy_assignment.inherit_tag

  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Tag Contributor"
  principal_id         = each.value.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}

# ---- Deny: resource types that should never appear --------------------------

resource "azurerm_subscription_policy_assignment" "denied_resource_types" {
  name                 = "lz-denied-resource-types"
  display_name         = "Landing zone: denied resource types"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = local.policy_definitions.not_allowed_resource_types

  parameters = jsonencode({
    listOfResourceTypesNotAllowed = { value = var.denied_resource_types }
  })
}

# ---- Deny: insecure data-plane defaults --------------------------------------

resource "azurerm_subscription_policy_assignment" "storage_secure_transfer" {
  name                 = "lz-storage-secure-transfer"
  display_name         = "Landing zone: storage accounts require HTTPS"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = local.policy_definitions.storage_secure_transfer

  parameters = jsonencode({ effect = { value = "Deny" } })
}

resource "azurerm_subscription_policy_assignment" "key_vault_purge_protection" {
  name                 = "lz-kv-purge-protection"
  display_name         = "Landing zone: key vaults require purge protection"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = local.policy_definitions.key_vault_purge_protection

  parameters = jsonencode({ effect = { value = "Deny" } })
}

# ---- Audit: surface drift without blocking -----------------------------------

resource "azurerm_subscription_policy_assignment" "storage_no_shared_key" {
  name                 = "lz-storage-no-shared-key"
  display_name         = "Landing zone: audit storage accounts allowing shared key access"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = local.policy_definitions.storage_disallow_shared_key

  parameters = jsonencode({ effect = { value = "Audit" } })
}

resource "azurerm_subscription_policy_assignment" "key_vault_rbac" {
  name                 = "lz-kv-rbac-model"
  display_name         = "Landing zone: audit key vaults not using RBAC"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = local.policy_definitions.key_vault_rbac_model

  parameters = jsonencode({ effect = { value = "Audit" } })
}

resource "azurerm_subscription_policy_assignment" "nic_no_public_ip" {
  name                 = "lz-nic-no-public-ip"
  display_name         = "Landing zone: audit network interfaces with public IPs"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = local.policy_definitions.nic_no_public_ip
}

resource "azurerm_subscription_policy_assignment" "subnet_requires_nsg" {
  name                 = "lz-subnet-requires-nsg"
  display_name         = "Landing zone: audit subnets without a network security group"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = local.policy_definitions.subnet_requires_nsg

  parameters = jsonencode({ effect = { value = "AuditIfNotExists" } })
}

resource "azurerm_subscription_policy_assignment" "audit_custom_rbac" {
  name                 = "lz-audit-custom-rbac"
  display_name         = "Landing zone: audit custom RBAC roles"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = local.policy_definitions.audit_custom_rbac_roles

  parameters = jsonencode({ effect = { value = "Audit" } })
}
