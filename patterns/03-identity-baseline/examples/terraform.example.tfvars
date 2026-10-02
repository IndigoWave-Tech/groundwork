# Example variables for Pattern 03: Identity Baseline.
# Copy to ../terraform/terraform.tfvars (ignored by git) and replace every value.
#
# BEFORE deploying: create two break-glass accounts and record their object IDs.
# See the guide, section 2. Deploying without real break-glass accounts is how
# organizations lock themselves out.

org_code = "contoso"

# Leave as report-only for the first deployment. Switch to "enabled" only after
# completing the rollout procedure in the guide.
policy_state = "enabledForReportingButNotEnforced"

# Object IDs (GUIDs) of the emergency access accounts. Not UPNs.
break_glass_account_object_ids = [
  "00000000-0000-0000-0000-000000000001",
  "00000000-0000-0000-0000-000000000002",
]

# Accounts that genuinely cannot do MFA. Ideally empty. Every entry needs a reason.
service_account_object_ids = []

# Office or VPN egress, if fixed. Marked trusted.
trusted_ip_ranges = ["203.0.113.10/32"]

# Where your people legitimately sign in from. Everything else is blocked (CA401).
# Leave empty to skip the geographic block.
allowed_countries = ["US"]

# Microsoft Entra ID P2 only. Microsoft 365 Business Premium includes P1, not P2.
enable_risk_policies = false

admin_sign_in_frequency_hours = 4

# From Pattern 01. Set to null to skip log export.
workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-platform-logging-contoso-prod-eus2/providers/Microsoft.OperationalInsights/workspaces/log-platform-contoso-prod-eus2"
