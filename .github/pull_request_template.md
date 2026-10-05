## What this changes

<!-- One or two sentences. Which blueprint, and what is new or different? -->

## Checklist

**Nothing environment-specific**
- [ ] No tenant IDs, subscription IDs, account IDs, or project IDs
- [ ] No client names, domains, or identifying details
- [ ] No secrets, keys, connection strings, or state files
- [ ] Only `*.example.tfvars` and `*.example.bicepparam` files added

**Documentation**
- [ ] Blueprint guide follows `docs/BLUEPRINT_TEMPLATE.md`
- [ ] Plain-language summary updated (what it protects from, monthly cost)
- [ ] Design decisions table updated for any non-obvious choice
- [ ] Status in the main README matches the blueprint's real state

**Truth check**
- [ ] No claims of client deployments, uptime, or certifications that cannot be proven
- [ ] Cost figures state their source, date, and assumptions

**Validation**
- [ ] CI passes
- [ ] If marking a blueprint Ready: deployed and torn down in a sandbox, validation checklist completed
