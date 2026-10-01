# 04 Backup and Recovery

> Status: Planned
> Clouds: Azure (Bicep, Terraform)

## In plain terms

**What this protects you from:** Ransomware, accidental deletion, and backups that fail exactly when you need them.

**What it costs to run:** to be published with the first release, with assumptions shown.

## Planned scope

- Recovery Services vault with immutability and soft delete
- Backup policies matched to realistic recovery point and recovery time targets
- Alerting on failed or missed backups
- A documented, repeatable restore test

Scope may change as the pattern is built. Every change and its reasoning will be recorded in the design decisions section of this guide.

---

This guide will follow the standard [pattern template](../../docs/PATTERN_TEMPLATE.md). See the [main README](../../README.md) for status definitions.
