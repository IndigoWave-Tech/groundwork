# Groundwork

**The cloud foundation most growing businesses skip, written down as code.**

Groundwork is an open library of infrastructure-as-code blueprints for small and mid-sized businesses: security, monitoring, backup, identity and cost guardrails that can be deployed, checked and rebuilt the same way every time. It is built and maintained by [IndigoWave Tech](https://indigowavetech.com), an Atlanta-based managed services provider.

Azure blueprints ship in both **Bicep** and **Terraform**. AWS and Google Cloud blueprints ship in **Terraform**.

**Contents**

- [What this repository is](#what-this-repository-is)
- [Who it is for](#who-it-is-for)
- [The blueprints](#the-blueprints)
- [How to use it](#how-to-use-it)
- [What is inside every blueprint](#what-is-inside-every-blueprint)
- [How changes are checked](#how-changes-are-checked)
- [Design principles](#design-principles)
- [Repository structure](#repository-structure)
- [Contributing and feedback](#contributing-and-feedback)
- [Using these blueprints responsibly](#using-these-blueprints-responsibly)
- [Want this run for you?](#want-this-run-for-you)

---

## What this repository is

Think of your cloud environment like a building. Nobody admires the foundation, but when it is missing, the cracks show up everywhere: a former employee who can still log in, a backup nobody has tested, a bill that doubled and nobody noticed until the invoice arrived.

Most small businesses build their cloud one urgent request at a time. Someone creates a storage account for a project, someone else opens a firewall port to fix a problem on a Friday, and two years later nobody can say exactly how the environment was put together or whether it is safe. Every setup ends up a little different, and every fix depends on the one person who remembers.

Groundwork takes the opposite approach. Each blueprint is a written, repeatable plan for one part of the foundation. Because the blueprint is code, it can be:

- **Deployed the same way every time**, so a new environment matches the last one
- **Checked automatically** against Microsoft, AWS and Google security guidance before anything is created
- **Reviewed line by line**, so every decision is visible and can be questioned
- **Rebuilt from scratch** after a mistake, an outage or a ransomware event
- **Handed to a new engineer or provider** without a knowledge transfer meeting

This is not a generic module collection. Microsoft, HashiCorp and others already publish excellent building blocks. Groundwork is the layer above those: opinionated, documented decisions about how a 50 to 500 person organization should assemble the blocks, and why.

### What this repository is not

- It is not a managed service. The code does not watch, patch or respond to anything on its own. That is what a provider does with it.
- It is not a one-click setup for every business. Every blueprint needs its parameters reviewed against your organization before it is deployed.
- It is not a compliance certification. Blueprints align with published frameworks and are checked against them, but alignment is not the same as an audit.

---

## Who it is for

**Business owners and executives.** You are not expected to read code. Each blueprint's guide opens with a plain-language summary that answers three questions: what does this protect me from, what does it cost to run each month, and why was each decision made. Use it to understand what a well-built foundation includes, to ask your current IT provider pointed questions, or to evaluate what IndigoWave Tech would deploy for you.

**Internal IT leads and office managers who own technology.** You are often one person covering everything. These blueprints give you a reviewed starting point instead of a blank page, and a documented standard you can hold your environment against. The deploy-from-zero guides assume nothing has been set up before.

**Cloud engineers and consultants.** You will find the full reasoning behind every non-obvious choice in each blueprint's design decisions table, with the rejected alternatives and the tradeoff. Disagree with a decision on purpose rather than by accident. Fork, adapt, and raise an issue if you think a default is wrong.

**Other managed service providers.** Use the blueprints as a reference for your own baseline, or as a shared vocabulary when a client asks what "secure by default" means in practice.

**Technical evaluators and reviewers.** If you are assessing IndigoWave Tech's approach to cloud architecture, this repository is the working example: the decisions, the documentation standard, the automated checks, and the way environment-specific data is kept out of code.

---

## The blueprints

| Blueprint | What it protects you from | Clouds | Status |
|---|---|---|---|
| [01 Secure Landing Zone](blueprints/01-landing-zone/) | A cloud setup with no structure, no guardrails, and nobody sure who changed what | Azure | In progress |
| [02 Overnight Watch](blueprints/02-monitoring-alerting/) | Problems that start at 2 a.m. and are only discovered when staff arrive | Azure | Planned |
| [03 Identity Baseline](blueprints/03-identity-baseline/) | Stolen passwords, risky sign-ins, and accounts that outlive the people who used them | Microsoft Entra ID | In progress |
| [04 Backup and Recovery](blueprints/04-backup-recovery/) | Ransomware, accidental deletion, and backups that fail exactly when you need them | Azure | Planned |
| [05 Cost Guardrails](blueprints/05-cost-guardrails/) | Surprise bills, forgotten resources, and spending nobody can explain | Azure | Planned |
| [06 Multi-Cloud Guardrails](blueprints/06-multicloud-guardrails/) | AWS and Google Cloud accounts running without the same protections as the rest of your business | AWS, Google Cloud | Planned |

Blueprints are numbered in the order most organizations should adopt them. The landing zone comes first because every other blueprint deploys into it.

**Status definitions**

| Status | Meaning |
|---|---|
| Planned | Scoped, not yet built |
| In progress | Code and guide complete and passing CI; not yet deployed and torn down in a sandbox |
| Ready | Passes CI, fully documented, and has been deployed and torn down in a sandbox subscription with the validation checklist completed |

---

## How to use it

### If you are a business owner

1. Open the blueprint that matches a worry you have (the table above is organized by what each one protects against).
2. Read the "In plain terms" section at the top of its guide. It is written for you, not for engineers.
3. Bring the three questions (what it protects, what it costs, why these decisions) to whoever manages your technology, or [book a consultation](#want-this-run-for-you) and we will walk through it together.

### If you are deploying a blueprint yourself

Each blueprint's guide has the exact steps for that blueprint. The general flow is the same for all of them.

**Step 1. Pick a blueprint and read the whole guide first.** Especially the prerequisites and design decisions. Do not deploy anything you have not read.

**Step 2. Clone the repository.**

```bash
git clone https://github.com/IndigoWave-Tech/groundwork.git
cd groundwork/blueprints/01-landing-zone
```

**Step 3. Install the tools listed in the blueprint's prerequisites.** Typically one or more of:

- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) with Bicep (`az bicep install`)
- [Terraform](https://developer.hashicorp.com/terraform/install)
- [AWS CLI](https://aws.amazon.com/cli/) or [Google Cloud CLI](https://cloud.google.com/sdk/docs/install) for blueprint 06

**Step 4. Copy the example parameter file and fill in your values.** Example files are the only parameter files committed to this repository. Your copy should never be committed anywhere public.

```bash
# Bicep: keep the copy next to the example so its "using" line still finds bicep/main.bicep
cp examples/main.example.bicepparam examples/main.local.bicepparam

# Terraform: a terraform.tfvars file in the terraform folder is loaded automatically
cp examples/terraform.example.tfvars terraform/terraform.tfvars
```

The `.gitignore` in this repository already excludes `*.local.bicepparam` and `*.tfvars` so a real file cannot be committed by accident.

**Step 5. Deploy to a sandbox first.** Use a non-production subscription, account or project. Follow the deploy-from-zero steps in the guide.

```bash
# Bicep example (subscription scope). The parameter file names the template in its
# "using" line, so --template-file is not passed; the CLI rejects the two together.
az deployment sub create \
  --location eastus2 \
  --parameters examples/main.local.bicepparam

# Terraform example
cd terraform
terraform init
terraform plan -out=plan.tfplan
terraform apply plan.tfplan
```

**Step 6. Run the validation checklist.** Every guide includes observable checks (a policy shows Compliant, an alert fires on a test condition, a restore succeeds). Do not consider the deployment done until each one passes.

**Step 7. Tear it down, then deploy for real.** Follow the teardown steps so nothing is left behind in the sandbox. Then repeat steps 4 through 6 against the real environment, with a change window and a rollback plan.

### If you are reviewing or adapting the code

- Each blueprint's design decisions table lists what was chosen, what was rejected, and why. Start there.
- [docs/CONVENTIONS.md](docs/CONVENTIONS.md) explains the naming, input, security and code rules every blueprint follows, so you can tell a deliberate choice from an accident.
- Run the same checks CI runs (see [How changes are checked](#how-changes-are-checked)) on your fork before relying on a change.
- Open an issue if you believe a default is wrong for the stated audience. Disagreement with reasoning attached is the most useful contribution.

---

## What is inside every blueprint

Each blueprint folder contains:

- **Deployable code** in Bicep and/or Terraform, with example parameter files only
- **An architecture diagram**, as a Mermaid block inside the guide so it renders on GitHub and changes with the text
- **A deploy-from-zero guide** that assumes nothing has ever been set up before
- **A validation checklist** to confirm the deployment did what it claims
- **A teardown procedure**
- **A monthly cost estimate** with its assumptions and date shown
- **A design decisions table** explaining what was chosen, what was rejected, and why

The structure is fixed by [docs/BLUEPRINT_TEMPLATE.md](docs/BLUEPRINT_TEMPLATE.md). If someone cannot deploy a blueprint using only its guide, the guide is treated as incomplete.

---

## How changes are checked

Every pull request and every push to `main` runs the [Validate workflow](.github/workflows/validate.yml). Nothing is merged on a failing check.

| Check | Tool | Purpose |
|---|---|---|
| Bicep build and lint | Bicep CLI | Code compiles and follows Bicep best practices |
| Azure best practice | PSRule for Azure | Alignment with the Azure Well-Architected Framework |
| Terraform format and validate | Terraform CLI | Consistent formatting and valid configuration |
| Terraform lint | TFLint | Catches errors and deprecated syntax before deployment |
| Security scan | Checkov | Flags insecure defaults and misconfigurations across all three clouds |

To run the same checks locally before opening a pull request:

```bash
# Bicep (replace 01-landing-zone with the blueprint you changed)
az bicep build --file blueprints/01-landing-zone/bicep/main.bicep --stdout > /dev/null
az bicep lint  --file blueprints/01-landing-zone/bicep/main.bicep
az bicep build-params --file blueprints/01-landing-zone/examples/main.example.bicepparam --stdout > /dev/null

# Terraform
terraform -chdir=blueprints/01-landing-zone/terraform fmt -check -recursive
terraform -chdir=blueprints/01-landing-zone/terraform init -backend=false
terraform -chdir=blueprints/01-landing-zone/terraform validate
tflint --init --config "$(pwd)/.tflint.hcl"
tflint --recursive --config "$(pwd)/.tflint.hcl"

# Security scan
pip install checkov
checkov --directory blueprints
```

Marking a blueprint **Ready** additionally requires a real deployment and teardown in a sandbox subscription, with the validation checklist completed against it.

---

## Design principles

- **Secure by default.** Insecure options require an explicit, documented override.
- **No secrets in code.** Credentials come from Key Vault, managed identities, or OIDC federation. Nothing is stored in a pipeline variable or a file.
- **Nothing environment-specific is committed.** Only `*.example.tfvars` and `*.example.bicepparam` files live in this repository. No tenant IDs, subscription IDs, account IDs, or client names.
- **Tagged for accountability.** Every resource carries owner, environment, and cost-center tags so every dollar can be traced.
- **Right-sized for the audience.** Defaults reflect a 50 to 500 person organization, not an enterprise. Where an enterprise control was deliberately left out, the design decisions table says so.
- **Built to be handed over.** The documentation standard exists so that a new engineer or a new provider can take over without a meeting.
- **Honest about status.** A blueprint is called Ready only after it has been deployed and torn down. Reference blueprints are described as reference blueprints, not as production history.

---

## Repository structure

```text
groundwork/
├── blueprints/
│   ├── 01-landing-zone/
│   ├── 02-monitoring-alerting/
│   ├── 03-identity-baseline/
│   ├── 04-backup-recovery/
│   ├── 05-cost-guardrails/
│   └── 06-multicloud-guardrails/
├── docs/
│   ├── BLUEPRINT_TEMPLATE.md    Standard structure every blueprint guide follows
│   └── CONVENTIONS.md         Naming, input, security and code rules every blueprint follows
├── .github/
│   ├── workflows/validate.yml Automated checks on every change
│   ├── pull_request_template.md
│   └── CODEOWNERS
├── bicepconfig.json           Bicep linter rules
├── ps-rule.yaml               PSRule for Azure options
├── .tflint.hcl                TFLint configuration
├── CONTRIBUTING.md            How to propose a change
├── SECURITY.md                How to report a vulnerability
├── LICENSE                    MIT
└── README.md
```

Every blueprint folder has the same layout:

```text
NN-blueprint-name/
├── README.md              Owner summary and full technical guide
├── bicep/                 Azure deployment (Bicep): main.bicep plus modules/
│   └── README.md          Only when a blueprint has no Bicep, explaining why (Blueprint 03)
├── terraform/             Deployment (Terraform)
├── examples/              Example parameter files, no real values
├── diagrams/              Exported images, if any; the diagram source is a Mermaid block in README.md
└── <shared>/              Optional: definitions both languages load (Blueprint 02 has workbook/)
```

---

## Contributing and feedback

Issues and pull requests are welcome. The most useful contributions are:

- A default you believe is wrong for a 50 to 500 person organization, with your reasoning
- A step in a deploy-from-zero guide that did not work as written
- A cost estimate that no longer matches current pricing

Every pull request goes through the template checklist: no environment-specific data, documentation updated, status accurate, and no claims that cannot be backed up. [CONTRIBUTING.md](CONTRIBUTING.md) has the branch, commit and local-check rules. Security problems go through [SECURITY.md](SECURITY.md), not a public issue.

---

## Using these blueprints responsibly

These are reference blueprints built to production standards. They are a strong starting point, not a substitute for understanding your own environment. Review every blueprint against your organization's requirements, and test in a non-production subscription or account before deploying anywhere that matters. Cloud charges from deploying these blueprints are your responsibility.

---

## Want this run for you?

IndigoWave Tech deploys, monitors, and maintains foundations like these as a managed service, with vCIO guidance on what to build next. If you would rather have this done than do it, start with a conversation.

**[Book a free consultation](https://calendly.com/indigowavetech/business-consultation?utm_source=github&utm_medium=readme&utm_campaign=groundwork)**

---

## License

[MIT](LICENSE). Copyright (c) 2026 IndigoWave Tech, LLC.
