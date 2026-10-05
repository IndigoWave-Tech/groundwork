# Contributing

Groundwork is maintained by IndigoWave Tech. Contributions are welcome, and the most useful ones are disagreements with reasoning attached: a default that is wrong for a 50 to 500 person organization, a deploy step that did not work as written, or a cost figure that no longer matches the price list.

Before changing anything, read [docs/CONVENTIONS.md](docs/CONVENTIONS.md). It explains why the code looks the way it does.

## What to open

| You want to | Do this |
|---|---|
| Report a step that failed, a wrong default, or a stale price | Open an issue. Say which blueprint, which language, which step, and what happened. |
| Report a security problem in a blueprint | Do not open a public issue. See [SECURITY.md](SECURITY.md). |
| Change documentation or fix a small bug | Open a pull request from a branch. |
| Add or substantially change a blueprint | Open an issue first so the scope and the design decisions can be agreed before code is written. |

## Branches and commits

- Branch from `main`. New blueprints use `blueprints/NN-<name>`; other work uses a short descriptive name such as `fix/02-heartbeat-window` or `docs/cost-labels`.
- One commit per logical unit. The title is imperative ("Add blueprint 04: Backup and Recovery", "Fix the heartbeat alert window"), followed by a blank line and a bullet body saying what changed and why.
- Commits are authored by a person, with a real name and email address. Commit messages carry no tool attribution trailers.
- After a blueprint merges, open blueprint branches are rebased onto `main`.

## Before you push

Run the checks CI runs, for the blueprint you changed:

```bash
# Bicep (where the blueprint has it)
az bicep build --file blueprints/NN-<name>/bicep/main.bicep --stdout > /dev/null
az bicep lint  --file blueprints/NN-<name>/bicep/main.bicep                                     # target: zero warnings
az bicep build-params --file blueprints/NN-<name>/examples/main.example.bicepparam --stdout > /dev/null

# Terraform
terraform -chdir=blueprints/NN-<name>/terraform fmt -check -recursive
terraform -chdir=blueprints/NN-<name>/terraform init -backend=false
terraform -chdir=blueprints/NN-<name>/terraform validate
tflint --init --config "$(pwd)/.tflint.hcl"
tflint --chdir=blueprints/NN-<name>/terraform --config "$(pwd)/.tflint.hcl"

# Security scan
pip install checkov
checkov -d blueprints/NN-<name> --framework terraform,bicep --quiet --compact

# Repository rule: no em dashes or en dashes anywhere (must print nothing)
grep -rnP '\xE2\x80[\x93\x94]' . --exclude-dir=.git
```

`terraform init` needs access to the provider registry. If it cannot run where you are, say so in the pull request and let CI confirm.

## Definition of done for a blueprint change

- [ ] Folder structure matches [docs/CONVENTIONS.md](docs/CONVENTIONS.md); example files use fictional values only
- [ ] Bicep builds with zero lint warnings; every suppression has a one-line reason
- [ ] `bicep build-params` succeeds on the example parameter file
- [ ] `terraform fmt -check`, TFLint and Checkov are clean, or every Checkov skip carries a reason pointing at the design decisions table
- [ ] The guide follows [docs/BLUEPRINT_TEMPLATE.md](docs/BLUEPRINT_TEMPLATE.md) section for section, with a catalog table where the blueprint deploys a family of things
- [ ] The design decisions table has a row for every non-obvious default and every piece of removed scope
- [ ] Every cost figure is labeled Estimate or Assumption, with method and date
- [ ] Every identifier (policy GUID, role template ID, API version, well-known application ID) was verified against Microsoft Learn or provider documentation, not recalled
- [ ] The root README catalog row shows the blueprint's real status
- [ ] No em dashes or en dashes in any file
- [ ] No tool attribution in any file or commit message

## Pull requests

The pull request template is a checklist; fill it in honestly. CI must pass. A maintainer reviews every change; expect questions about reasoning rather than style.

Only a maintainer moves a blueprint to **Ready**, and only after deploying and tearing it down in a sandbox with the validation checklist completed. A pull request can take a blueprint from Planned to In progress; it cannot take it to Ready.

## License

By contributing you agree that your contribution is licensed under the [MIT License](LICENSE).
