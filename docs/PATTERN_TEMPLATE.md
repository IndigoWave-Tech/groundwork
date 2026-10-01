# Pattern Guide Template

Every pattern's `README.md` follows this structure. Copy it into a new pattern folder and replace every bracketed placeholder.

**The rule:** assume the reader has never deployed anything before. If someone cannot deploy this pattern from zero using only this guide, the guide is incomplete. If it is not written down, it does not exist.

**The truth rule:** describe what the pattern does and what it has been tested against. Never claim client deployments, uptime figures, or compliance certifications that cannot be proven.

---

````markdown
# [NN] [Pattern Name]

> Status: Planned | In progress | Ready
> Clouds: Azure (Bicep, Terraform) | AWS (Terraform) | Google Cloud (Terraform)
> Last validated: [YYYY-MM-DD]

## In plain terms

**What this protects you from:** [One or two sentences a business owner understands without a glossary.]

**What it costs to run:** about $[X] per month. [Link to the cost section below for assumptions.]

**What you get:** [Three to five bullets describing outcomes, not resources.]

---

## 1. Overview

- **Business objective:** [What problem this solves and for whom.]
- **What gets deployed:** [Resource-level summary.]
- **Architecture:** [One paragraph, plus the diagram below.]

[Architecture diagram: a Mermaid block here (GitHub renders it), or an image in diagrams/]

## 2. Prerequisites

| Requirement | Detail |
|---|---|
| Accounts and subscriptions | [e.g., Azure subscription with Owner role] |
| CLI tools and versions | [e.g., Azure CLI 2.x, Bicep 0.x, Terraform 1.x] |
| Permissions and roles | [Exact roles, at what scope] |
| App registrations and API scopes | [If any] |
| Environment variables | [Name, purpose, example value] |
| DNS or networking | [If any] |

## 3. Folder structure

```text
[NN-pattern-name]/
├── README.md
├── bicep/
├── terraform/
├── diagrams/
└── examples/
```

Secrets are injected at: [Key Vault reference, pipeline variable, or OIDC; never in files].

## 4. Deploy from zero

### Option A: Bicep

1. [Step]
2. [Step]

### Option B: Terraform

1. [Step]
2. [Step]

## 5. Validation checklist

- [ ] [Observable check, e.g., "Policy assignment X shows Compliant in the portal"]
- [ ] [Observable check]
- [ ] [Observable check]

## 6. Teardown

1. [Step, including anything that must be removed manually or has soft-delete protection]

## 7. Design decisions

| Decision | Chosen | Rejected | Why |
|---|---|---|---|
| [Topic] | [Option] | [Alternative] | [Tradeoff in one or two sentences] |

## 8. Security model

- [Identity and access approach]
- [Secret handling]
- [Logging and audit trail]

## 9. Cost breakdown

| Resource | SKU or tier | Estimated monthly cost | Assumption |
|---|---|---|---|
| [Resource] | [SKU] | $[X] | [Region, usage level] |

Estimates are produced with [Azure Pricing Calculator / Infracost] on [YYYY-MM-DD] and will vary by region and usage.

## 10. Production readiness

- [ ] CI checks pass (Bicep lint, PSRule, Terraform validate, TFLint, Checkov)
- [ ] Deployed to a sandbox subscription or account
- [ ] Validation checklist completed against that deployment
- [ ] Torn down cleanly with no orphaned resources
- [ ] Cost estimate confirmed

## Changelog

| Date | Change |
|---|---|
| [YYYY-MM-DD] | Initial release |
````
