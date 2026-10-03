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
    blueprint = "groundwork-02-overnight-watch"
  })

  subscription_id = data.azurerm_subscription.current.id

  # Workbook names must be UUIDs. Derive one so redeploys update in place.
  workbook_name = uuidv5("url", "groundwork/${local.suffix}/overnight-summary")
}
