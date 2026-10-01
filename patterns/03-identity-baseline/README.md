# 03 Identity Baseline

> Status: In progress (code passes CI; awaiting first sandbox deployment)
> Clouds: Microsoft Entra ID (Terraform). No Bicep: see [bicep/README.md](bicep/README.md) for why.
> Requires: Microsoft Entra ID P1 (included in Microsoft 365 Business Premium, E3, E5). Pattern 01 optional, for log export.
> Last validated: not yet deployed

## In plain terms

**What this protects you from:** stolen passwords, risky sign-ins, and accounts that outlive the people who used them. Most business email compromise starts with one password, phished or guessed, used from somewhere your staff have never been. This pattern makes a password alone insufficient, closes the old protocols that attackers use to sidestep MFA, and keeps a locked-and-documented emergency key so you can never be locked out of your own tenant.

**What it costs to run:** **$0** beyond licensing you already have. Conditional Access is part of Entra ID P1, which Microsoft 365 Business Premium includes. The optional risk-based policies need P2.

**What you get:**

- Every sign-in requires a second factor, with a short, reviewed list of exceptions
- Administrators are held to a higher standard: MFA everywhere, sessions that expire, no "stay signed in" on admin portals
- Legacy email protocols (the ones that cannot do MFA) are blocked
- An attacker who steals a password cannot register their own phone as the second factor
- Optional: sign-ins from countries where you have no staff are blocked
- Two emergency "break-glass" accounts that bypass every rule, so a misconfiguration can never lock out the business
- Every policy starts in **report-only mode**: it records what it *would* have done for a week or more before it is turned on, so you see the impact before anyone is affected

---

## 1. Overview

**Business objective.** Make identity the perimeter. For a 50 to 500 person organization on Microsoft 365, the firewall is mostly irrelevant; the attack surface is the login page. This pattern applies Microsoft's own recommended baseline policies as code, with a safe rollout procedure and the exclusions that stop a mistake from becoming an outage.

**What gets deployed.** Into a Microsoft Entra ID tenant:

| Area | Resources |
|---|---|
| Exclusion groups | 2 security groups: break-glass exclusions, MFA-exempt accounts |
| Named locations | Trusted office egress IPs (optional), allowed countries (optional) |
| Conditional Access, always | 7 policies: CA001, CA101, CA102, CA103, CA201, CA202, CA203 |
| Conditional Access, P2 only | 2 policies: CA301, CA302 (when `enable_risk_policies = true`) |
| Conditional Access, optional | 1 policy: CA401 (when `allowed_countries` is set) |
| Log export | Entra sign-in and audit logs to the Pattern 01 workspace (optional) |

**Architecture.** Policies target the whole tenant and exclude groups, never individual users, so changing who is exempt never means changing a policy. Two exclusion groups exist because two different questions are being asked: "who must bypass everything in an emergency" (break-glass, excluded from all policies) and "who genuinely cannot perform MFA" (service accounts, excluded from MFA requirements only, still blocked from legacy authentication). Every policy's state is one variable, so the whole baseline moves from report-only to enforced in a single reviewed change.

```mermaid
flowchart TB
    subgraph tenant["Microsoft Entra ID tenant"]
        subgraph groups["Exclusion groups"]
            bg["Break Glass<br/>excluded from ALL policies"]
            mfaex["MFA Exempt<br/>excluded from MFA only"]
        end
        subgraph loc["Named locations"]
            office["Trusted office egress"]
            countries["Allowed countries"]
        end
        subgraph ca["Conditional Access (state = one variable)"]
            ca0["CA001 Block legacy auth"]
            ca1["CA101 MFA all users<br/>CA102 MFA guests<br/>CA103 MFA to register security info"]
            ca2["CA201 MFA admins (14 roles)<br/>CA202 MFA Azure management<br/>CA203 Admin session limits"]
            ca3["CA301 Sign-in risk (P2)<br/>CA302 User risk (P2)"]
            ca4["CA401 Block other countries"]
        end
    end
    bg -.->|excluded| ca0
    bg -.->|excluded| ca1
    bg -.->|excluded| ca2
    bg -.->|excluded| ca3
    bg -.->|excluded| ca4
    mfaex -.->|excluded| ca1
    mfaex -.->|excluded| ca2
    mfaex -.->|excluded| ca3
    office -.->|skips| ca1
    countries -.->|allows| ca4
    tenant -->|SignInLogs, AuditLogs| law["Log Analytics workspace<br/>(Pattern 01)"]
```

### The policy catalog

| Policy | Who | What | Exclusions | Why |
|---|---|---|---|---|
| CA001 Block legacy authentication | All users | Block Exchange ActiveSync and "other clients" (IMAP, POP3, SMTP AUTH, older Office) | Break-glass only | Legacy protocols cannot do MFA, so they are the bypass attackers reach for first. No exemptions: if a device needs legacy auth, fix the device. |
| CA101 Require MFA for all users | All users, all apps | Require MFA | Break-glass, MFA-exempt | The single most effective control against password compromise. |
| CA102 Require MFA for guests | All external user types | Require MFA | Break-glass | Redundant with CA101 today, so that guest MFA survives if CA101 is ever relaxed for staff. |
| CA103 Require MFA to register security info | All users, except from trusted locations | Require MFA | Break-glass, MFA-exempt, guests | Stops an attacker with a stolen password from enrolling their own authenticator. Trusted office IPs are excluded so new hires can register on day one. |
| CA201 Require MFA for administrators | 14 admin roles, all apps | Require MFA | Break-glass only | Microsoft's own role list. The MFA-exempt group does not apply to admins, on purpose. |
| CA202 Require MFA for Azure management | All users accessing the Azure Resource Manager API | Require MFA | Break-glass, MFA-exempt | Covers portal, CLI, PowerShell. A compromised account with Azure access can delete the business. |
| CA203 Admin session limits | 14 admin roles, Microsoft admin portals and Azure | Sign-in frequency 4 hours (configurable), no persistent browser | Break-glass only | A stolen admin session on a shared machine is worth far less when it expires. |
| CA301 Sign-in risk (P2) | All users, medium or high sign-in risk | Require MFA, re-authenticate hourly | Break-glass, MFA-exempt | Identity Protection flags impossible travel, anonymous IPs, leaked credentials. |
| CA302 User risk (P2) | All users, high user risk | Require MFA and password change | Break-glass, MFA-exempt | A user whose credentials are confirmed leaked changes their password on next sign-in. |
| CA401 Block other countries | All users from any location not in the allowed list, including unknown | Block | Break-glass only | If nobody works from there, nobody should sign in from there. Travelling staff need a documented exception process. |

## 2. Prerequisites

| Requirement | Detail |
|---|---|
| Licensing | Microsoft Entra ID P1 for every user subject to Conditional Access. Business Premium, E3 and E5 include it. P2 (E5, or add-on) for CA301 and CA302. |
| Security defaults | Must be **off**. Conditional Access and security defaults cannot coexist. Entra admin center > Identity > Overview > Properties > Manage security defaults. |
| Two break-glass accounts | Create them **before** deploying. Cloud-only (`*.onmicrosoft.com`), Global Administrator, no MFA registered, 64+ character passwords stored offline in two separate physical locations (a safe, not a password manager). Record each account's **object ID**. See the [Microsoft guidance](https://learn.microsoft.com/entra/identity/role-based-access-control/security-emergency-access). |
| Deploying identity | A user holding **Conditional Access Administrator** and **Groups Administrator**. Global Administrator also works but is more than needed. If using a service principal, Graph permissions `Policy.ReadWrite.ConditionalAccess`, `Policy.Read.All`, `Group.ReadWrite.All`, `Application.Read.All`. |
| For log export | Contributor on the Pattern 01 workspace resource group, and the deploying identity must be Global Administrator or Security Administrator (Entra diagnostic settings are tenant-level). |
| Azure CLI | 2.60 or later, signed in to the correct tenant: `az login --tenant <tenant-id> --allow-no-subscriptions`. |
| Terraform | 1.9 or later. Providers: `hashicorp/azuread` 3.x, `hashicorp/azurerm` 4.x. |
| Information to have ready | Break-glass object IDs; any accounts that truly cannot do MFA and the reason for each; office egress IPs; countries staff sign in from; whether the tenant has P2. |

**Finding object IDs.** `az ad user show --id breakglass1@contoso.onmicrosoft.com --query id -o tsv`

**MFA registration.** Before moving CA101 from report-only to enabled, every user needs a registered MFA method or they will be prompted to register at next sign-in, which is acceptable for most organizations but should be communicated. Check registration status: Entra admin center > Protection > Authentication methods > User registration details.

## 3. Folder structure

```text
03-identity-baseline/
├── README.md                          This guide
├── bicep/
│   └── README.md                      Why this pattern has no Bicep
├── terraform/
│   ├── versions.tf                    Provider pins and required permissions
│   ├── variables.tf                   Inputs with validation (two break-glass IDs enforced)
│   ├── locals.tf                      Role template IDs, app IDs, exclusion sets
│   ├── main.tf                        Exclusion groups, named locations, log export
│   ├── conditional-access.tf          The ten policies
│   └── outputs.tf
├── examples/
│   └── terraform.example.tfvars
└── diagrams/
```

**Secret injection points.** None. Object IDs and IP ranges are not secrets but are tenant-specific; keep `terraform.tfvars` out of version control. Terraform state contains the same IDs; store it in the protected backend from Pattern 01.

## 4. Deploy from zero

### Step 0: Create the break-glass accounts (once, by hand)

This is deliberately manual. Terraform would put the passwords in state.

```bash
az login --tenant <tenant-id> --allow-no-subscriptions

# Create two accounts. Use long random passwords generated offline; do not paste them into a terminal history.
az ad user create --display-name "Emergency Access 1" --user-principal-name breakglass1@<tenant>.onmicrosoft.com --password '<64+ char password>' --force-change-password-next-sign-in false
az ad user create --display-name "Emergency Access 2" --user-principal-name breakglass2@<tenant>.onmicrosoft.com --password '<64+ char password>' --force-change-password-next-sign-in false

# Assign Global Administrator (role template 62e90394-69f5-4237-9190-012177145e10)
for upn in breakglass1 breakglass2; do
  az rest --method POST --url "https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignments" \
    --body "{\"principalId\":\"$(az ad user show --id ${upn}@<tenant>.onmicrosoft.com --query id -o tsv)\",\"roleDefinitionId\":\"62e90394-69f5-4237-9190-012177145e10\",\"directoryScopeId\":\"/\"}"
done

# Record the object IDs for terraform.tfvars
az ad user show --id breakglass1@<tenant>.onmicrosoft.com --query id -o tsv
az ad user show --id breakglass2@<tenant>.onmicrosoft.com --query id -o tsv
```

Write the passwords on paper. Seal them. Store them in two separate locations with two different people aware of each. Test one of them signing in, then do not use them again except in an emergency. Pattern 02's Overnight Watch should alert on any break-glass sign-in; add that rule when Pattern 03 reaches Ready.

### Step 1: Deploy in report-only mode

```bash
cd groundwork/patterns/03-identity-baseline
cp examples/terraform.example.tfvars terraform/terraform.tfvars
# Edit terraform/terraform.tfvars. Confirm policy_state is enabledForReportingButNotEnforced.

cd terraform
terraform init
terraform plan -out=idb.tfplan     # Expect 2 groups, 0 to 2 named locations, 7 to 10 policies, 0 or 1 diagnostic setting
terraform apply idb.tfplan
```

Nothing changes for any user at this point. Policies evaluate and log; they do not enforce.

### Step 2: Observe for at least 7 days

In the Entra admin center, Protection > Conditional Access > Insights and reporting, or query the workspace:

```kusto
SigninLogs
| where TimeGenerated > ago(7d)
| mv-expand ConditionalAccessPolicies
| where ConditionalAccessPolicies.displayName startswith "CA"
| where ConditionalAccessPolicies.result in ("reportOnlyFailure", "reportOnlyInterrupted")
| summarize WouldHaveBeenAffected = dcount(UserPrincipalName), SignIns = count()
    by Policy = tostring(ConditionalAccessPolicies.displayName)
| order by SignIns desc
```

For every row, decide: is that expected? `reportOnlyFailure` on CA001 means someone is using legacy authentication right now; find the device before enabling. `reportOnlyInterrupted` on CA101 means a user would be prompted for MFA; that is the goal, but confirm they have a method registered.

### Step 3: Enable, in order

Change `policy_state = "enabled"` and apply. Everything switches at once. If you would rather stage it, the recommended order and the reason:

1. **CA201, CA202, CA203** (admins). Smallest population, highest value, and admins can self-serve any problem.
2. **CA001** (legacy auth). Only after the report-only data shows zero legitimate legacy sign-ins.
3. **CA101, CA102, CA103** (everyone). Communicate the date a week ahead.
4. **CA401** (countries). Only after confirming the allowed list against where staff actually signed in from in the last 30 days.
5. **CA301, CA302** (risk). P2 tenants only.

To stage, temporarily set `state` on individual policies in `conditional-access.tf` to `"enabled"` while the variable stays report-only, or run the whole thing through the variable and accept the single cutover. Either way, keep a break-glass session open in a private browser window during the change.

## 5. Validation checklist

- [ ] **Exclusion groups exist with the right members.** `az ad group member list --group "<ORG> Groundwork CA Exclusion - Break Glass" --query "[].userPrincipalName" -o tsv` lists exactly the two break-glass accounts and nothing else.
- [ ] **All policies exist in the expected state.** `az rest --method GET --url "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies" --query "value[?starts_with(displayName,'CA')].{name:displayName, state:state}" -o table` shows 7 to 10 rows, all `enabledForReportingButNotEnforced` (or `enabled` after rollout).
- [ ] **Break-glass is excluded from every policy.** Same call, `--query "value[?starts_with(displayName,'CA')].{name:displayName, excludedGroups:conditions.users.excludeGroups}"`. Every row includes the break-glass group ID.
- [ ] **Break-glass can sign in with a password alone.** From a private browser window, sign in as breakglass1. No MFA prompt, even after enablement. Sign out. Record the test in your change log.
- [ ] **Report-only results are flowing.** After 24 hours, the KQL in Step 2 returns rows (or the Insights workbook shows data). If zero rows after 48 hours of normal activity, check the diagnostic setting and that sign-ins are occurring.
- [ ] **Legacy auth has no legitimate users** (before enabling CA001). `SigninLogs | where TimeGenerated > ago(7d) | where ClientAppUsed !in ("Browser", "Mobile Apps and Desktop clients") | summarize count() by UserPrincipalName, ClientAppUsed, AppDisplayName`. Every row must be explainable and fixable.
- [ ] **After enablement: MFA is actually required.** Sign in as a normal test user from a new device. An MFA prompt appears. Sign in as an admin test user to portal.azure.com. MFA prompt appears, and the session expires after the configured hours.
- [ ] **After enablement: nothing broke overnight.** Check Pattern 02's Overnight Summary the next morning for a spike in failed sign-ins. Some increase is normal; a cliff means a group was missed.

## 6. Teardown

```bash
cd terraform
terraform destroy
```

This removes the policies, named locations, exclusion groups, and the diagnostic setting. It does **not** remove the break-glass accounts (they were created by hand) and it does not re-enable security defaults. A tenant with neither Conditional Access nor security defaults has no MFA enforcement at all; if you are tearing down for good rather than redeploying, turn security defaults back on immediately.

## 7. Design decisions

| Decision | Chosen | Rejected | Why |
|---|---|---|---|
| Terraform only | `azuread` provider | Bicep with a deployment script; Graph Bicep extension; exported JSON | Conditional Access is a Graph object, not an ARM resource. See [bicep/README.md](bicep/README.md). |
| Report-only by default | One `policy_state` variable, default report-only | Deploy enabled; or no variable, hand-edit each policy | Report-only is how you find the device still using IMAP before you lock it out. One variable makes the cutover a single reviewed diff. |
| Two exclusion groups | Break-glass (all policies) and MFA-exempt (MFA policies only) | One exclusion group | Service accounts that cannot do MFA must still be blocked from legacy authentication. One group would exempt them from everything. |
| Break-glass created by hand | Documented procedure, object IDs as input | Terraform-managed users | Terraform would store the passwords in state. Emergency credentials belong on paper in a safe, not in a state file. |
| At least two break-glass accounts | Variable validation enforces `>= 2` | One | One account is a single point of failure, and Microsoft's guidance says two. |
| Groups, not users, in policies | All exclusions via group membership | Named users in `excluded_users` | Membership changes are a group edit with an audit trail, not a policy change that requires a plan and apply. |
| Microsoft's 14 admin roles | Exactly the template list, as template IDs | A shorter list; or all directory roles | Microsoft's list is defensible to any auditor. Template IDs are stable across tenants; display names are not. |
| MFA-exempt does not apply to admins | CA201 and CA203 exclude break-glass only | Consistent exclusions everywhere | An administrator who cannot perform MFA should not be an administrator. |
| CA102 guests redundant with CA101 | Deployed anyway | Omit as redundant | Defence in depth against a future relaxation of CA101. Zero cost. |
| CA103 excludes trusted locations | Security info registration allowed without MFA from the office | Require MFA to register everywhere | A new hire has no MFA method to satisfy the requirement. Trusted office egress is the pragmatic answer; organizations with Temporary Access Pass workflows can remove the exclusion. |
| Session limits only for admins | CA203 targets 14 roles | Sign-in frequency for all users | Hourly or daily re-authentication for every employee is friction that produces MFA fatigue and workarounds. Admin sessions are where the damage is. |
| Country block optional | Only when `allowed_countries` is set | Always on; or never | Right for most domestic SMBs, wrong for any with travelling staff and no exception process. Make it a decision, not a default. |
| Risk policies gated on P2 | `enable_risk_policies`, default false | Always deploy | On a P1 tenant they create silently and never fire, which is worse than absent because it looks like coverage. |
| No device compliance policies | Not included | Require compliant or hybrid-joined device | Needs Intune enrolment across the fleet first. That is a device management pattern, not an identity baseline. |
| No phishing-resistant MFA requirement | Standard MFA control | Authentication strength: phishing-resistant for admins | Right target, wrong day one. Requires every admin to have a FIDO2 key or Windows Hello enrolled first, or they are locked out. Document as the next step after Ready. |
| Log export in this pattern | Entra diagnostic setting to Pattern 01 workspace | Leave to Pattern 02 | The report-only review in Step 2 needs the logs, so the pattern that needs them ships them. |

## 8. Security model

- **Identity and access.** The deploying identity needs Conditional Access Administrator and Groups Administrator. Nothing else is granted. The two exclusion groups are owned by the deploying identity so ownership is auditable.
- **Lockout protection.** Break-glass accounts are excluded from every policy by group membership, validated as at least two, and tested by the checklist. Keep a break-glass session open during any enablement change.
- **Exclusion group drift.** Anyone with Groups Administrator can add a member to the MFA-exempt group and bypass MFA. Review both groups quarterly; alert on membership changes once Pattern 02 covers Entra audit logs (the audit log is exported by this pattern, so the query is possible today).
- **State.** Terraform state contains group and policy object IDs. Not secrets, but tenant-identifying. Use the protected backend.
- **Logging.** Sign-in, non-interactive sign-in, service principal, managed identity, audit, and risk logs flow to the Pattern 01 workspace for 90 days.

## 9. Cost breakdown

| Resource | Estimated monthly cost | Assumption |
|---|---|---|
| Conditional Access policies, named locations, groups | $0 | Included in Entra ID P1. |
| Entra ID P1 licensing | $0 incremental | Already held via Microsoft 365 Business Premium, E3 or E5. Standalone P1 is a licensing decision outside this pattern. |
| Entra ID P2 (optional, for CA301 and CA302) | $0 incremental if held | If not held, this pattern does not require it; leave `enable_risk_policies = false`. |
| Entra log export to Log Analytics | roughly $0 to $15 | Sign-in logs are billable ingestion at $2.30/GB (see Pattern 01). A 100-user organization typically generates well under 200 MB/day. Covered by the Pattern 01 daily cap. |
| **Total** | **$0 to $15** | The only variable cost is log volume, already budgeted in Pattern 01. |

Estimate method: Microsoft Learn licensing documentation and Azure Monitor pricing, checked 2026-10-01.

## 10. Production readiness

- [x] CI checks pass (Terraform fmt, TFLint, Checkov)
- [ ] Terraform validate against provider schemas (runs in GitHub Actions on pull request)
- [ ] Deployed to a test tenant in report-only mode
- [ ] Break-glass sign-in tested with no MFA prompt
- [ ] 7 days of report-only data reviewed, all `reportOnlyFailure` rows explained
- [ ] Moved to enabled in a test tenant; MFA prompts confirmed for user and admin
- [ ] Torn down cleanly; security defaults re-enabled on the test tenant
- [ ] Break-glass sign-in alert added to Pattern 02

The pattern moves to **Ready** when every box is checked.

## Changelog

| Date | Change |
|---|---|
| 2026-10-01 | Initial build: Terraform implementation, policy catalog, rollout procedure, guide, CI passing. Bicep intentionally absent, with reasoning. |
