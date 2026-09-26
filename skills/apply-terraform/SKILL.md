---
name: apply-terraform
description: Apply exactly one saved, policy-checked Terraform plan that a human has explicitly approved, then verify the result. Use only when the user says to apply/deploy a specific reviewed plan.
---

# Apply Terraform

## Preconditions (all required)

- A saved plan from the `plan-terraform` skill exists, and its policy gate passed.
- The human explicitly approved **this** plan in this conversation ("apply the
  plan", "go ahead and deploy"). A request to write, fix, review, or plan is
  not approval.
- The configuration has not changed since the plan was created. If it has,
  create a new plan and ask for approval again.
- The identity and target environment match the plan report.

## Procedure

```bash
terraform -chdir=<dir> apply <path/to/tfplan>
```

A saved plan applies without an interactive prompt. That is intended: the
approval happened on the reviewed plan. Never use `-auto-approve`, and never
run `apply` without a plan file. The repository guard hook blocks both.

If Terraform reports the plan is stale, stop and re-plan.

## Teardown

`terraform destroy` is blocked for agents. To decommission, create a destroy
plan with `scripts/capture-plan.sh <dir> -- -destroy`, report it with the
`plan-terraform` template, and apply that saved plan only after approval.
Protected resource types fail the policy gate unless the human records them in
`exceptions.allow_destroy`.

## After apply

1. Verify outcomes, not just exit codes: `terraform -chdir=<dir> output`, plus
   read-only provider checks (for example `az aks show`, resource health).
2. Run `terraform -chdir=<dir> plan -detailed-exitcode`. Exit code 0 means no
   drift remains.
3. Record the apply output next to the plan evidence (outside Git).

## On failure

- Report the exact error and which resources were created before it failed.
- Do **not** retry automatically, destroy, taint, or edit state. Re-plan and
  bring the new plan back for approval.
