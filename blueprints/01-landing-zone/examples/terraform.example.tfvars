# Example variables for Blueprint 01: Secure Landing Zone.
# Copy to ../terraform/terraform.tfvars (ignored by git) and replace every value.

org_code          = "contoso"
environment       = "prod"
location          = "eastus2"
allowed_locations = ["eastus2", "centralus"]

tags = {
  owner       = "it@contoso.example"
  environment = "prod"
  costCenter  = "IT-100"
}

security_contact_email = "security@contoso.example"
security_contact_phone = "+14045550100"
monthly_budget_amount  = 1500

hub_address_space    = "10.0.0.0/16"
shared_subnet_prefix = "10.0.1.0/24"

# Office egress IP ranges, if you want to reach the Key Vault from them directly,
# for example ["203.0.113.10/32"]. Empty allows only trusted Azure services.
key_vault_allowed_ip_ranges = []

log_retention_days = 90
log_daily_quota_gb = 5

# Paid Defender plans (Servers Plan 1, Key Vault). Off until there are servers to protect;
# Blueprint 02's Defender alert is live only when this is true. See the cost breakdown.
enable_defender_plans = false
