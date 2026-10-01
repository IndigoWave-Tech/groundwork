locals {
  region_short = {
    eastus         = "eus"
    eastus2        = "eus2"
    centralus      = "cus"
    westus2        = "wus2"
    westus3        = "wus3"
    southcentralus = "scus"
    northcentralus = "ncus"
    canadacentral  = "cnc"
    northeurope    = "neu"
    westeurope     = "weu"
    uksouth        = "uks"
    australiaeast  = "aue"
  }

  loc    = lookup(local.region_short, var.location, substr(var.location, 0, 4))
  suffix = "${var.org_code}-${var.environment}-${local.loc}"

  rg_names = {
    logging  = "rg-platform-logging-${local.suffix}"
    network  = "rg-platform-network-${local.suffix}"
    security = "rg-platform-security-${local.suffix}"
  }

  tags = merge(var.tags, {
    pattern = "groundwork-01-landing-zone"
  })

  required_tag_names = ["owner", "environment", "costCenter"]

  builtin = "/providers/Microsoft.Authorization/policyDefinitions"
  policy_definitions = {
    allowed_locations                     = "${local.builtin}/e56962a6-4747-49cd-b67b-bf8b01975c4c"
    allowed_locations_for_resource_groups = "${local.builtin}/e765b5de-1225-4ba3-bd56-1ac6695af988"
    require_tag_on_resource_groups        = "${local.builtin}/96670d01-0a4d-4649-9c89-2d3abc0a5025"
    inherit_tag_from_resource_group       = "${local.builtin}/ea3f2387-9b95-492a-a190-fcdc54f7b070"
    not_allowed_resource_types            = "${local.builtin}/6c112d4e-5bc7-47ae-a041-ea2d9dccd749"
    storage_secure_transfer               = "${local.builtin}/404c3081-a854-4457-ae30-26a93ef643f9"
    storage_disallow_shared_key           = "${local.builtin}/8c6a50c6-9ffd-4ae7-986f-5fa6111f9a54"
    key_vault_purge_protection            = "${local.builtin}/0b60c0b2-2dc2-4e1c-b5c9-abbed971de53"
    key_vault_rbac_model                  = "${local.builtin}/12d4fa5e-1f9f-4c21-97a9-b99b3c6611b5"
    nic_no_public_ip                      = "${local.builtin}/83a86a26-fd1f-447c-b59d-e51f44264114"
    subnet_requires_nsg                   = "${local.builtin}/e71308d3-144b-4262-b144-efdc3cc90517"
    audit_custom_rbac_roles               = "${local.builtin}/a451c1ef-c6ca-483d-87ed-f49761e3ffb5"
  }

  # Key Vault names: globally unique, 3 to 24 characters.
  key_vault_name = substr(
    "kv-${var.org_code}-plat-${var.environment}-${substr(sha1(data.azurerm_subscription.current.subscription_id), 0, 8)}",
    0, 24
  )

  # First day of the current month, for the budget start date.
  budget_start_date = formatdate("YYYY-MM-01'T'00:00:00Z", timestamp())
}
