# Conventions

Every blueprint in Groundwork follows the same rules for names, inputs, security and code shape. This page is the reference for those rules. It exists so that a reviewer can tell a deliberate choice from an accident, and so that a contributor can build a new blueprint that looks and behaves like the existing ones.

Where a blueprint deviates from a rule, its design decisions table says so and why.

## 1. Status and truth

Each blueprint has exactly one status, defined in the [root README](../README.md): Planned, In progress, or Ready. Ready is earned only by a real deployment and teardown in a sandbox with the validation checklist completed. Until then a blueprint is described as a reference blueprint built to production standards, never as deployed, proven, or in use.

Every cost figure says where it came from and when: an estimate names its method and date; an assumption gives its reasoning.

Owner-facing sections ("In plain terms" at the top of each guide) use plain language. Analogies are welcome; resource type names are not.

No em dashes or en dashes appear anywhere in the repository: not in code comments, documentation, or commit messages. Use a comma, a colon, a period, or parentheses.

## 2. Naming

Resources are named `<type>-<workload>-<suffix>`, where `<type>` is the Microsoft Cloud Adoption Framework abbreviation for the resource type and `<suffix>` is `<orgCode>-<environment>-<regionShort>`.

| Part | Source | Example |
|---|---|---|
| type | Cloud Adoption Framework abbreviation | `rg`, `log`, `vnet`, `kv`, `ag` |
| workload | What the resource is for, fixed by the blueprint | `platform-logging`, `hub`, `critical` |
| orgCode | Input: 2 to 8 lowercase letters or digits | `contoso` |
| environment | Input: one of `prod`, `nonprod`, `sandbox` | `prod` |
| regionShort | Derived from `location` by the table below | `eus2` |

Examples: `rg-platform-logging-contoso-prod-eus2`, `log-platform-contoso-prod-eus2`, `ag-critical-contoso-prod-eus2`.

The region map is identical in every blueprint's `main.bicep` (the `regionShort` variable) and `locals.tf` (the `region_short` local). A region not in the table falls back to the first four characters of its name.

| Region | Short | Region | Short |
|---|---|---|---|
| eastus | eus | northcentralus | ncus |
| eastus2 | eus2 | canadacentral | cnc |
| centralus | cus | northeurope | neu |
| westus2 | wus2 | westeurope | weu |
| westus3 | wus3 | uksouth | uks |
| southcentralus | scus | australiaeast | aue |

Resource groups are `rg-platform-<purpose>-<suffix>`, and each blueprint owns its own: Blueprint 01 owns `logging`, `network` and `security`; Blueprint 02 owns `monitoring`; Blueprint 04 will own `backup`; Blueprint 05 owns no resource group unless it needs one for cost exports (`finops`).

Display names of alerts and policy assignments carry a blueprint prefix so they can be told apart in a portal list: `Landing zone: <what>` (01), `Overnight Watch: <what>` (02), `CA<nnn> - <what>` (03), `Backup: <what>` (04), `Cost guardrail: <what>` (05).

Tags: every resource group carries `owner`, `environment` and `costCenter`. Blueprint 01 requires them by policy and inherits them to resources. Every blueprint adds `blueprint = groundwork-NN-<name>` to its deployment tags, where `NN-<name>` is the blueprint's folder name.

Globally unique names with a length limit (Key Vault, storage accounts) are built from a shortened form of the suffix plus a deterministic hash, computed in one place, and both languages must produce the same name. The guide states the worked length for the longest allowed inputs.

## 3. Inputs and outputs

Every Azure blueprint takes `orgCode` / `org_code`, `environment` (`prod`, `nonprod`, `sandbox`), `location`, and `tags` (an object with `owner`, `environment`, `costCenter`). Later blueprints use the same values as Blueprint 01. A tenant-scoped blueprint (03) omits `environment`, `location` and `tags` because Microsoft Entra objects have none, and says so in its guide.

Anything one blueprint needs from another is a resource ID passed as an input, never looked up by name. Blueprint 02 takes `workspaceResourceId` from Blueprint 01's `logAnalyticsWorkspaceId` output; Blueprints 04 and 05 take the action group IDs from Blueprint 02. No blueprint hard-codes another blueprint's names. Each guide ends its deploy section with an outputs table saying which later blueprint consumes each output.

Every Bicep parameter has `@description`, plus `@allowed`, `@minValue`, `@maxValue` or `@minLength` where a range or format exists. Every Terraform variable has `description` and a `validation` block for anything with a format or range. Bicep and Terraform validate the same things, so the two paths accept and reject the same inputs.

A default encodes an opinion: a parameter with a default is a decision the deployer can override; a parameter without one is information only the deployer has.

Example files use fictional values only: `contoso`, `*.example` email domains, `00000000-0000-0000-0000-00000000000N` GUIDs, `203.0.113.x` IP addresses, `4045550100` phone numbers.

## 4. Security and secrets

Nothing environment-specific is committed: no tenant IDs, subscription IDs, client names, state files or secrets. The `.gitignore` blocks `*.tfvars` (except `*.example.tfvars`), `*.local.bicepparam`, `*.tfstate*`, `.env*`, `*.pem`, `*.pfx` and `*.key`. Do not weaken it.

No secrets in code. Credentials come from Azure CLI login, OIDC federation in CI, managed identities, or Key Vault references. A blueprint that needs a secret documents the Key Vault secret name it reads, never the value.

Secure by default. An insecure option requires an explicit parameter and a row in the design decisions table.

Terraform state lives in a storage account created outside this repository. Every `versions.tf` carries a commented `backend "azurerm"` block pointing at the key `groundwork/NN-<blueprint>.tfstate`. Local state is acceptable for a sandbox run only.

Azure provider features are set for safety over convenience: `prevent_deletion_if_contains_resources = true`; for Key Vault, `purge_soft_delete_on_destroy = false` and `recover_soft_deleted_key_vaults = true`. Every blueprint sets them explicitly rather than relying on provider defaults.

A Checkov skip is allowed only with an inline reason that points at the design decisions table:

```text
// checkov:skip=CKV_AZURE_189: Public endpoint by design, see README design decisions   (Bicep)
#checkov:skip=CKV_AZURE_189: Public endpoint by design, see README design decisions     (Terraform)
```

A skip without a reason fails review.

## 5. Code shape

**Bicep.** The entry point is `main.bicep` with `targetScope = 'subscription'`. It creates the resource groups and calls `modules/*.bicep` with `scope: rg`. Modules target the resource group or the subscription as appropriate. Outputs carry `@description`.

**Terraform.** Files are split by topic: `versions.tf`, `variables.tf`, `locals.tf`, `main.tf`, `<topic>.tf`, `outputs.tf`. Families of similar resources (alerts, policy assignments) are a `locals` catalog map iterated with `for_each`, so the catalog reads as a table and the resource count in the guide is honest.

**Definitions shared by both languages** (a workbook, a policy JSON) live in a blueprint-level folder and are loaded with `loadTextContent()` in Bicep and `file("${path.module}/../<folder>/<file>")` in Terraform.

**When the `azurerm` provider models something differently from ARM** (for example one `operation_name` per activity log alert where ARM accepts a list), split for Terraform, keep coverage identical, and record the count difference in the design decisions table.

**Deterministic GUIDs** for resources that need one: `guid(resourceGroup().id, '<purpose>')` in Bicep, `uuidv5("url", "groundwork/<suffix>/<purpose>")` in Terraform, so a redeploy updates in place instead of duplicating.

**First-of-month dates** (budgets): `param startDate string = '${utcNow('yyyy-MM')}-01'` in Bicep; `formatdate("YYYY-MM-01'T'00:00:00Z", timestamp())` with `lifecycle { ignore_changes = [time_period] }` in Terraform.

**Deploying a Bicep parameter file.** A `.bicepparam` file names its template in its `using` line, so the Azure CLI takes only `--parameters` and rejects `--template-file` alongside it. Copies of the example stay in `examples/` so the relative `using` path still resolves:

```bash
cp examples/main.example.bicepparam examples/main.local.bicepparam
az deployment sub create --location <region> --parameters examples/main.local.bicepparam
```

**Identifiers are verified, not recalled.** Policy definition GUIDs, role template IDs, well-known application IDs and API versions are checked against Microsoft Learn or the provider documentation when written, and the source is cited in a comment. Reuse the values already in the repository rather than retyping them.

## 6. Linting rules

`bicepconfig.json` sets `no-hardcoded-env-urls`, `secure-secrets-in-params` and `outputs-should-not-contain-secrets` to error, and `no-unused-params`, `no-unused-vars` and `use-recent-api-versions` to warning. The target is zero warnings. When an API version warning cannot be avoided, suppress it with `#disable-next-line use-recent-api-versions` preceded by a one-line comment saying why that version is required.

Checkov's Bicep parser cannot handle a multi-line function call inside a `var` declaration. Keep `var x = fn(a, b)` on one line.

TFLint runs the `terraform` recommended preset plus a pinned ruleset for each cloud that has a blueprint, configured in `.tflint.hcl` at the repository root. A rule disabled there carries a comment with the reason, the same standard as a Bicep suppression.

## 7. Documentation

Every guide follows [BLUEPRINT_TEMPLATE.md](BLUEPRINT_TEMPLATE.md) section for section. The test is simple: hand the guide to someone who has never seen the repository or the subscription. If they would need to ask a question, the guide is incomplete.

The design decisions table (Decision, Chosen, Rejected, Why) is the most-read section by reviewers. Every non-obvious default gets a row. Removed scope gets a row.
