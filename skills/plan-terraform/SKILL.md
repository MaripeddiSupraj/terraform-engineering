---
name: plan-terraform
description: Create a saved Terraform plan, run the plan policy gate, and summarize blast radius (destroys, replacements, IAM, network exposure, data stores) for human approval. Use whenever infrastructure changes need to be previewed or before any apply.
---

# Plan Terraform

Scripts referenced below live in this framework's `scripts/` directory:
`${CLAUDE_PLUGIN_ROOT}/scripts` when installed as a plugin, or `scripts/` at the
root of the terraform-engineering repository.

## Preconditions

- The `validate-terraform` gates passed for the target directory.
- The backend and cloud identity are the intended ones. Confirm with a
  read-only command (for example `az account show`, `aws sts get-caller-identity`,
  `gcloud config list`) and state the subscription/account/project in your report.

## Procedure

1. Initialize with the real backend: `terraform -chdir=<dir> init -input=false`.
2. Create the plan, evidence, summary and policy result in one step:

   ```bash
   scripts/capture-plan.sh <dir>
   ```

   This writes `tfplan`, `plan.txt`, `plan.json`, `summary.md` and `policy.txt`
   under `<dir>/.evidence/<timestamp>/` and runs `scripts/policy-check.sh`.
   Without the script, the equivalent is `terraform plan -out=tfplan`,
   `terraform show -json tfplan > plan.json`, then
   `scripts/policy-check.sh plan.json <dir>`.
3. If the **policy gate fails**, fix the configuration. Only propose an entry in
   `.terraform-policy-exceptions.yaml` when the human has stated the change is
   intended (for example a planned replacement), and call it out explicitly.
4. Read `plan.txt` for every destroy/replace and explain *why* Terraform wants
   it (which attribute forces replacement).
5. **Stop at the approval boundary.** Report and wait.

## Report template

```text
Target: <dir>  Backend: <state key>  Identity: <subscription/account>
Plan: <n> create, <n> update, <n> replace, <n> destroy
Policy gate: passed | failed (<rules>) | not evaluated (<why>)
Destroy/replace: <addresses + forcing attribute>
IAM/RBAC changes: <addresses>
Network exposure changes: <addresses>
Data stores touched: <addresses>
Cost-significant resources: <e.g. node pools, SKUs>
Saved plan: <path>  (apply only this file, only after approval)
```

## Never

- Never apply in this skill.
- Never commit `tfplan`, `plan.json`, or `.evidence/`; they can contain secrets.
- Never use `-lock=false` or `-refresh=false` to get a plan through.
