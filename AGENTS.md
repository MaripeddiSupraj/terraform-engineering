# Agent Operating Contract

This file is authoritative for every AI coding agent and human automation operating this repository.

## Mission

Create and maintain production-quality Terraform using reviewed, provider-native modules and controlled execution. The repository must remain usable without any specific AI vendor.

## Non-negotiable rules

1. **Read before write.** Inspect the target blueprint, module READMEs, versions, tests, and relevant standards before changing code.
2. **Compose before generating.** Prefer existing reviewed modules. Create a new module only when no appropriate module exists.
3. **Keep providers separated.** Azure code belongs under Azure paths, AWS under AWS paths, and so on. Never build a multi-cloud resource module selected by a provider string.
4. **No secrets.** Never commit credentials, tokens, passwords, client secrets, private keys, kubeconfigs, `.tfstate`, saved plans, or sensitive evidence.
5. **No hidden mutation.** Cloud CLI commands are read-only for discovery unless the task explicitly calls for a bootstrap action that is documented as mutable.
6. **Terraform owns infrastructure.** Do not fix drift by manually changing cloud resources when the desired state belongs in Terraform.
7. **No blind apply.** Never use `terraform apply -auto-approve`. Produce a saved plan and stop at the approval boundary unless the user explicitly authorizes apply.
8. **Small changes.** Keep changes reviewable. Do not rewrite unrelated modules while completing a request.
9. **Provider-native design.** Preserve cloud capabilities rather than forcing a lowest-common-denominator abstraction.
10. **Evidence over claims.** Report exactly what was formatted, initialized, validated, tested, scanned, planned, applied, and verified. Do not claim a check passed if it did not run.

## Required workflow

For infrastructure changes:

```text
understand request
  -> normalize requirements
  -> select provider + blueprint
  -> inspect approved modules
  -> design change
  -> implement
  -> terraform fmt
  -> terraform init -backend=false (where appropriate)
  -> terraform validate
  -> terraform test
  -> lint/security checks when installed
  -> terraform plan -out=<plan>
  -> summarize blast radius
  -> human approval
  -> terraform apply <plan>
  -> verify
  -> capture evidence outside Git
```

## Code quality contract

- Use standard Terraform file names: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, plus `locals.tf` only when useful.
- Inputs must have explicit types and meaningful descriptions.
- Add validation when Terraform can catch an invalid input early.
- Outputs must be intentional; do not expose secret material by convenience.
- Prefer `for_each` with stable keys over positional `count` when resources have identity.
- Avoid unnecessary `depends_on`; use reference-based dependencies.
- Avoid provisioners unless there is a documented exceptional reason.
- Avoid `null_resource` for orchestration.
- Pin provider compatibility ranges in reusable modules and pin tested versions in root examples/blueprints.
- Comments explain **why** a decision exists, not what obvious HCL syntax already says.
- Tags/labels must be passed consistently through provider modules.

## Security contract

Reject or redesign code that:

- embeds credentials in HCL, tfvars, workflows, examples, or scripts;
- enables public access without an explicit documented requirement;
- outputs passwords, private keys, kubeconfigs, or tokens;
- uses long-lived cloud keys in CI where workload identity/OIDC is available;
- commits `.terraform`, `.tfstate`, `.tfplan`, crash logs, or `.evidence` artifacts;
- disables security controls merely to make a plan pass.

## Provider discovery

When a version-sensitive resource or field is being changed, verify against the current official Terraform provider documentation before implementing. Do not rely on remembered schemas.

## Apply boundary

A request to *write*, *review*, *fix*, *plan*, or *prepare* Terraform is not authorization to apply it. Apply requires explicit human intent to execute the reviewed plan.

## Done means

A change is only complete when the final report states:

- files changed;
- commands actually executed;
- checks that passed/failed/skipped;
- Terraform plan summary if a plan was possible;
- remaining risks or prerequisites;
- whether any cloud mutation occurred.
