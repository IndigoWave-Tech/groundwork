# Security

Groundwork publishes infrastructure-as-code blueprints that deploy security controls. A mistake in a blueprint can weaken the environment of everyone who deploys it, so reports are taken seriously and handled privately until a fix is available.

## Reporting a vulnerability

Use GitHub's private vulnerability reporting: open the repository's **Security** tab and choose **Report a vulnerability**. Do not open a public issue or pull request for a security problem.

Include:

- The blueprint, the language (Bicep or Terraform) and the file
- What the blueprint does wrong, and what an attacker or a mistake could do as a result
- How you found it, and how to reproduce it in a sandbox
- Whether you have already written a fix, and what it was

You will receive an acknowledgement within three business days. A fix or a written assessment follows within thirty days for anything confirmed. Credit is given in the blueprint's changelog if you want it.

## What counts

In scope: anything in this repository that would make a deployed blueprint less secure than its guide claims. Examples: a policy that does not enforce what the design decisions table says, a default that exposes a resource, a teardown step that leaves data behind, a secret or environment-specific value that was committed.

Out of scope: vulnerabilities in Azure, AWS or Google Cloud services themselves (report those to the provider); environments deployed by others from a modified copy of a blueprint; and the gaps a blueprint already lists in its security model section as known and by design.

## What these blueprints are

The blueprints are reference baselines built to production standards. They are not a managed service and they do not watch, patch or respond to anything after deployment. Each guide's security model section states what the blueprint protects, what it deliberately leaves out, and which later blueprint or decision covers the gap. Read it before deploying anywhere that matters.
