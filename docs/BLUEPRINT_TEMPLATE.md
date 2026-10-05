# Blueprint Guide Template

Every blueprint's `README.md` follows this structure, in this order, with every section present. Copy the block below into a new blueprint folder and replace every bracketed placeholder. Blueprint 03's guide is a complete worked example.

**The rule:** assume the reader has never deployed anything before. If someone cannot deploy this blueprint from zero using only this guide, the guide is incomplete. If it is not written down, it does not exist.

**The truth rule:** describe what the blueprint does and what it has been tested against. Never claim client deployments, uptime figures, or compliance certifications that cannot be proven. The status vocabulary is exactly three words, defined in the root README: Planned, In progress, Ready.

**Who reads what:** business owners read "In plain terms" and stop. IT leads read everything from Prerequisites to Teardown and follow it step by step. Engineers and reviewers go to Design decisions first. Write each section for its reader.

**Formatting notes:** the header block ends each line with a backslash so GitHub renders the four lines separately. The diagram is a Mermaid block inside the guide, not an image file, so it renders on GitHub and changes with the text. No em dashes or en dashes anywhere.

---

````markdown
# [NN] [Blueprint Name]

> Status: Planned | In progress | Ready \
> Clouds: Azure (Bicep, Terraform) | AWS (Terraform) | Google Cloud (Terraform) \
> Requires: [Blueprint NN (what it provides), or "none"] \
> Last validated: [YYYY-MM-DD, or "not yet deployed"]

## In plain terms

**What this protects you from:** [One or two sentences a business owner understands without a glossary. No resource type names.]

**What it costs to run:** about $[X] per month. [Say whether the figure is fixed or scales with something, and point to section 9 for the assumptions.]

**What you get:** [Three to five bullets describing outcomes, not resources.]

---

## 1. Overview

**Business objective.** [What problem this solves and for whom.]

**What gets deployed.** [Where it deploys, then the table.]

| Area | Resources |
|---|---|
| [Area] | [What, with counts] |

**Architecture.** [One paragraph, then the diagram.]

```mermaid
flowchart TB
    [The diagram source lives here.]
```

### The [policy | alert | backup policy | control] catalog

[Only when the blueprint deploys a family of similar things. One row per item: what it is, who or what it applies to, what it does, exclusions, why.]

## 2. Prerequisites

| Requirement | Detail |
|---|---|
| Licensing | [What must be licensed, and which plans include it] |
| Roles | [Exact role names at the exact scope, for a user and for a service principal] |
| Resource providers | [Providers to register, or "none beyond the defaults"] |
| CLI tools and versions | [Azure CLI 2.x, Bicep 0.x, Terraform 1.x, provider versions] |
| Earlier blueprints | [Outputs needed from Blueprint NN and the command that prints them] |
| Information to have ready | [Every value the deployer must know before starting] |

## 3. Folder structure

```text
NN-blueprint-name/
├── README.md              This guide
├── bicep/                 main.bicep (subscription scope) and modules/
├── terraform/             versions.tf, variables.tf, locals.tf, main.tf, <topic>.tf, outputs.tf
├── examples/              main.example.bicepparam, terraform.example.tfvars (fictional values only)
└── diagrams/              Exported images, if any; the source is the Mermaid block above
```

**Secret injection points.** [Usually "None". Otherwise: the Key Vault secret name read, the pipeline variable, or the OIDC federation. Never a value.]

## 4. Deploy from zero

### Before either path

[Sign in, pick the subscription, register providers, gather the outputs of earlier blueprints. Every command. Say "pick one path, do not run both".]

### Option A: Bicep

```bash
# Copy the example next to itself so its "using" line still finds bicep/main.bicep.
# The .local. name is ignored by git.
cp examples/main.example.bicepparam examples/main.local.bicepparam
# Edit examples/main.local.bicepparam and replace every value.

# The parameter file names the template in its "using" line, so --template-file is not passed.
az deployment sub what-if --name groundwork-[nn] --location <region> --parameters examples/main.local.bicepparam
az deployment sub create  --name groundwork-[nn] --location <region> --parameters examples/main.local.bicepparam

# Capture the outputs the next blueprint needs
az deployment sub show --name groundwork-[nn] --query properties.outputs -o json
```

### Option B: Terraform

```bash
# terraform.tfvars is ignored by git.
cp examples/terraform.example.tfvars terraform/terraform.tfvars
# Edit terraform/terraform.tfvars and replace every value.

cd terraform
terraform init                      # For a kept environment, configure the backend in versions.tf first.
terraform plan -out=[nn].tfplan     # Expect [N] resources to add, 0 to change, 0 to destroy.
terraform apply [nn].tfplan
terraform output -json              # Capture the outputs the next blueprint needs
```

### Outputs

| Output (Bicep / Terraform) | Used by |
|---|---|
| [name / snake_name] | [Blueprint NN, as input X] |

## 5. Validation checklist

- [ ] **[Observable result.]** [The exact command or portal path, and what it must show.]
- [ ] **[Observable result.]** [...]

## 6. Teardown

1. [Ordered steps. Call out soft delete, purge protection, retention locks, auto-created resources, and anything that must be removed by hand.]

## 7. Design decisions

| Decision | Chosen | Rejected | Why |
|---|---|---|---|
| [Topic] | [Option] | [Alternative] | [Tradeoff in one or two sentences] |

[Every non-obvious default gets a row. Removed scope gets a row. Every Checkov skip and every insecure option points at a row here.]

## 8. Security model

- **Identity and access.** [What the deploying identity needs and what the blueprint grants.]
- **Secrets.** [Where secrets come from; usually none in this blueprint.]
- **Network.** [Public endpoints, private endpoints, firewall defaults.]
- **Logging.** [What is logged, where, for how long.]
- **Known gaps by design.** [What this blueprint deliberately does not do, and which blueprint or decision covers it.]

## 9. Cost breakdown

| Resource | SKU or tier | Monthly estimate | Assumption |
|---|---|---|---|
| [Resource] | [SKU] | $[X] | Estimate: [method] or Assumption: [reasoning] |
| **Total** | | **$[X] to $[Y]** | [What drives the range] |

Every figure is labeled Estimate (with its method) or Assumption (with its reasoning). Estimate method: [price list or calculator used], checked [YYYY-MM-DD]. Prices vary by region and usage.

## 10. Production readiness

- [ ] CI checks pass (Bicep lint, PSRule, Terraform validate, TFLint, Checkov)
- [ ] Deployed to a sandbox subscription or account
- [ ] Validation checklist completed against that deployment
- [ ] Torn down cleanly with no orphaned resources
- [ ] Cost estimate confirmed against the sandbox bill

The blueprint moves to **Ready** when every box is checked.

## Changelog

| Date | Change |
|---|---|
| [YYYY-MM-DD] | Initial release |
````
