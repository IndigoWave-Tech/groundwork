# Groundwork

**The cloud foundation most growing businesses skip, written down as code.**

Groundwork is an open library of infrastructure-as-code patterns for small and mid-sized businesses: security, monitoring, backup, identity and cost guardrails that can be deployed, checked and rebuilt the same way every time. It is built and maintained by [IndigoWave Tech](https://indigowavetech.com).

Azure patterns ship in both **Bicep** and **Terraform**. AWS and Google Cloud patterns ship in **Terraform**.

---

## For business owners

Think of your cloud environment like a building. Nobody admires the foundation, but when it is missing, the cracks show up everywhere: a former employee who can still log in, a backup nobody has tested, a bill that doubled and nobody noticed until the invoice arrived.

Most small businesses build their cloud one urgent request at a time, so every setup ends up a little different and nobody can say exactly how it was put together. Groundwork takes the opposite approach. Each pattern is a written, repeatable blueprint, so your environment can be built correctly the first time, checked automatically, and rebuilt from scratch if it ever has to be.

| Pattern | What it protects you from | Status |
|---|---|---|
| [01 Secure Landing Zone](patterns/01-landing-zone/) | A cloud setup with no structure, no guardrails, and nobody sure who changed what | Planned |
| [02 Overnight Watch](patterns/02-monitoring-alerting/) | Problems that start at 2 a.m. and are only discovered when staff arrive | Planned |
| [03 Identity Baseline](patterns/03-identity-baseline/) | Stolen passwords, risky sign-ins, and accounts that outlive the people who used them | Planned |
| [04 Backup and Recovery](patterns/04-backup-recovery/) | Ransomware, accidental deletion, and backups that fail exactly when you need them | Planned |
| [05 Cost Guardrails](patterns/05-cost-guardrails/) | Surprise bills, forgotten resources, and spending nobody can explain | Planned |
| [06 Multi-Cloud Guardrails](patterns/06-multicloud-guardrails/) | AWS and Google Cloud accounts running without the same protections as the rest of your business | Planned |

Every pattern's guide opens with a plain-language summary that answers three questions:

1. **What does this protect me from?**
2. **What does it cost to run each month?**
3. **Why was each decision made?**

---

## For IT leads and engineers

Each pattern is opinionated on purpose. The defaults reflect what a 50 to 500 person organization on Microsoft 365 typically needs, and every non-obvious choice is written down with its tradeoff so you can disagree with it on purpose rather than by accident.

**What every pattern includes**

- Deployable code: Bicep and/or Terraform, with example parameter files only
- An architecture diagram
- A deploy-from-zero guide that assumes nothing has ever been set up before
- A validation checklist to confirm the deployment did what it claims
- A teardown procedure
- A monthly cost estimate with its assumptions shown
- A decision log explaining what was chosen, what was rejected, and why

**What every change is checked against**

| Check | Tool | Purpose |
|---|---|---|
| Bicep build and lint | Bicep CLI | Code compiles and follows Bicep best practices |
| Azure best practice | PSRule for Azure | Alignment with the Azure Well-Architected Framework |
| Terraform format and validate | Terraform CLI | Consistent formatting and valid configuration |
| Terraform lint | TFLint | Catches errors and deprecated syntax before deployment |
| Security scan | Checkov | Flags insecure defaults and misconfigurations |

**Status definitions**

| Status | Meaning |
|---|---|
| Planned | Scoped, not yet built |
| In progress | Code exists and passes CI, documentation incomplete |
| Ready | Passes CI, fully documented, and has been deployed and torn down in a sandbox subscription |

**Design principles**

- **Secure by default.** Insecure options require an explicit, documented override.
- **No secrets in code.** Credentials come from Key Vault, managed identities, or OIDC federation.
- **Nothing environment-specific is committed.** Only `*.example.tfvars` and `*.example.bicepparam` files live in this repository.
- **Tagged for accountability.** Every resource carries owner, environment, and cost-center tags.
- **Built to be handed over.** If someone cannot deploy a pattern using only its guide, the guide is incomplete.

---

## Repository structure

```text
groundwork/
├── patterns/
│   ├── 01-landing-zone/
│   │   ├── README.md          Owner summary and full technical guide
│   │   ├── bicep/             Azure deployment (Bicep)
│   │   ├── terraform/         Azure deployment (Terraform)
│   │   ├── diagrams/          Architecture diagrams
│   │   └── examples/          Example parameter files, no real values
│   ├── 02-monitoring-alerting/
│   ├── 03-identity-baseline/
│   ├── 04-backup-recovery/
│   ├── 05-cost-guardrails/
│   └── 06-multicloud-guardrails/
├── docs/
│   └── PATTERN_TEMPLATE.md    Standard structure every pattern guide follows
└── .github/
    └── workflows/validate.yml Automated checks on every change
```

---

## Using these patterns

These are reference patterns built to production standards. They are a strong starting point, not a substitute for understanding your own environment. Review every pattern against your organization's requirements, and test in a non-production subscription or account before deploying anywhere that matters.

## Want this run for you?

IndigoWave Tech deploys, monitors, and maintains foundations like these as a managed service, with vCIO guidance on what to build next.

**[Book a free consultation](https://calendly.com/indigowavetech/business-consultation?utm_source=github&utm_medium=readme&utm_campaign=groundwork)**

## License

[MIT](LICENSE). Copyright (c) 2026 IndigoWave Tech, LLC.
