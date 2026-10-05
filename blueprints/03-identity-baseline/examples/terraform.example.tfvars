# Example variables for Blueprint 03: Identity Baseline.
# Copy to ../terraform/terraform.tfvars (ignored by git) and replace every value.
#
# BEFORE deploying: create two break-glass accounts and record their object IDs.
# See the guide, section 4, step 0. Deploying without real break-glass accounts
# is how organizations lock themselves out.

# Short organization code, 2 to 8 lowercase letters or digits. Match Blueprint 01.
# Group and named-location names start with it in upper case ("CONTOSO Groundwork ...").
org_code = "contoso"

# Leave as report-only for the first deployment. Switch to "enabled" only after
# completing the rollout procedure in the guide.
policy_state = "enabledForReportingButNotEnforced"

# Object IDs (GUIDs) of the emergency access accounts. Not UPNs. At least two.
break_glass_account_object_ids = [
  "00000000-0000-0000-0000-000000000001",
  "00000000-0000-0000-0000-000000000002",
]

# Accounts that genuinely cannot do MFA. Ideally empty. Every entry needs a reason.
# On a hybrid tenant, the directory synchronization account belongs here.
service_account_object_ids = []

# Office or VPN egress, if fixed. Marked trusted; lets new hires register security
# information from the office (CA103).
trusted_ip_ranges = ["203.0.113.10/32"]

# Where your people legitimately sign in from, as ISO 3166-1 alpha-2 codes.
# Empty skips the geographic block (CA401), which is the right default until you
# have checked 30 days of sign-in locations and agreed an exception process.
allowed_countries = []
# allowed_countries = ["US"]

# Microsoft Entra ID P2 only. Microsoft 365 Business Premium includes P1, not P2.
enable_risk_policies = false

# Hours before an administrator must sign in again to the admin portals (CA203).
# Whole number, 1 to 24.
admin_sign_in_frequency_hours = 4

# From Blueprint 01: terraform output -raw log_analytics_workspace_id
# Set to null to skip log export; the azurerm provider then takes its subscription
# from your CLI login (see the guide).
workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-platform-logging-contoso-prod-eus2/providers/Microsoft.OperationalInsights/workspaces/log-platform-contoso-prod-eus2"
