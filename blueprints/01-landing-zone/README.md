# 01 Secure Landing Zone

> Status: Planned
> Clouds: Azure (Bicep, Terraform)

## In plain terms

**What this protects you from:** A cloud setup with no structure, no guardrails, and nobody sure who changed what.

**What it costs to run:** to be published with the first release, with assumptions shown.

## Planned scope

- Management group and subscription structure sized for a small business, not an enterprise
- Baseline Azure Policy assignments (allowed regions, required tags, secure defaults)
- Central logging with Log Analytics and activity log export
- Role-based access with least-privilege defaults
- Hub network with sensible address planning for future growth

Scope may change as the blueprint is built. Every change and its reasoning will be recorded in the design decisions section of this guide.

---

This guide will follow the standard [blueprint template](../../docs/BLUEPRINT_TEMPLATE.md). See the [main README](../../README.md) for status definitions.
