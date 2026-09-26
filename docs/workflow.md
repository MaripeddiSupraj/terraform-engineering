# Agentic Terraform Workflow

Each phase maps to a skill in `skills/`. Enforcement points are marked **(enforced)**.

## Phase 1: Understand (`design-infrastructure`)

Normalize provider, environment, region, capability, security constraints,
availability and scale into the request contract
(`schemas/infrastructure-request.schema.json`). **(enforced)** The schema and
`scripts/request-to-tfvars.py` reject incomplete or contradictory requests,
such as a public control plane that isn't explicitly allowed and restricted.

## Phase 2: Design

Select an existing blueprint, identify approved modules, and call out any new
module before writing it. Surface decisions that change cost, security or
topology. The human approves the design.

## Phase 3: Implement (`author-module` when needed)

Make the smallest composable change. **(enforced)** Module validations and
preconditions reject insecure inputs at plan time.

## Phase 4: Prove quality (`validate-terraform`)

fmt, validate, native tests, TFLint, Trivy. Report exact results; "this should
work" is not evidence. **(enforced)** in CI on every pull request.

## Phase 5: Plan (`plan-terraform`)

`scripts/capture-plan.sh` creates a saved plan, plan JSON, a blast-radius
summary and the policy result. **(enforced)** The OPA policy gate denies
protected destroys, public exposure, missing tags and privileged IAM.

## Phase 6: Approve

A human approves the exact saved plan. A changed configuration requires a new
plan. **(enforced)** The guard hook blocks `-auto-approve`, `apply` without a
plan file, and `destroy`. Claude Code also asks before any `terraform apply`.

## Phase 7: Apply and verify (`apply-terraform`)

Apply the saved plan, verify outputs and health, confirm no remaining diff
(`plan -detailed-exitcode`), and keep evidence outside Git.

## Operating existing infrastructure

- Adopt resources with `import` blocks (`import-resources`), never `terraform import`.
- Investigate drift with refresh-only plans (`detect-drift`), never with cloud CLI changes.
