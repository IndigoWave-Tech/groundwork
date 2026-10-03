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

  tags = merge(var.tags, {
    blueprint = "groundwork-02-monitoring-alerting"
  })

  subscription_id = data.azurerm_subscription.current.id

  # Global covers incidents that are not tied to one region (identity, portal, DNS).
  # Added here rather than validated, so both paths behave the same whatever the input.
  service_health_regions = distinct(concat(var.service_health_regions, ["Global"]))

  # Workbook names must be UUIDs. Derive one so redeploys update in place.
  workbook_name = uuidv5("url", "groundwork/${local.suffix}/overnight-summary")
}
