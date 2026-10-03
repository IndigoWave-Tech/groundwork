# Example variables for Blueprint 02: Overnight Watch.
# Copy to ../terraform/terraform.tfvars (ignored by git) and replace every value.
# Deploy Blueprint 01 first; this blueprint needs its workspace ID.

org_code    = "contoso"
environment = "prod"
location    = "eastus2"

tags = {
  owner       = "it@contoso.example"
  environment = "prod"
  costCenter  = "IT-100"
}

# From Blueprint 01: terraform output -raw log_analytics_workspace_id
workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-platform-logging-contoso-prod-eus2/providers/Microsoft.OperationalInsights/workspaces/log-platform-contoso-prod-eus2"

# Critical: wakes someone up. Email plus SMS.
critical_emails = ["oncall@contoso.example"]
critical_sms_receivers = [
  { country_code = "1", phone_number = "4045550100" }
]

# Warning: reviewed in the morning.
warning_emails = ["it@contoso.example"]

# Display names, not region codes. Global is added automatically.
service_health_regions = ["East US 2", "Central US"]

heartbeat_missing_minutes = 10
low_disk_free_percent     = 10
