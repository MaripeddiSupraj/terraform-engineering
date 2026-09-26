---
name: detect-drift
description: Detect and explain drift between Terraform state/configuration and real cloud resources using read-only refresh plans, then propose a reviewed fix in code. Use when asked whether infrastructure matches Terraform, after incidents, or on a schedule.
---

# Detect drift

## Procedure

1. Initialize the target root with its real backend and confirm the identity
   (read-only), as in `plan-terraform`.
2. Detect changes made outside Terraform:

   ```bash
   terraform -chdir=<dir> plan -refresh-only -detailed-exitcode -out=refresh.tfplan
   ```

   Exit code 0 = no drift, 2 = drift, 1 = error.
3. Detect configuration that no longer matches reality:

   ```bash
   terraform -chdir=<dir> plan -detailed-exitcode -out=tfplan
   terraform -chdir=<dir> show -json tfplan > plan.json
   python3 scripts/plan-summary.py plan.json
   ```

4. For each drifted resource, classify it:
   - **Unapproved manual change**: restore the declared state through a normal
     reviewed plan.
   - **Legitimate change made outside Terraform**: update the configuration to
     match, and plan until the diff is gone.
   - **Owned by another controller** (autoscaler, policy, platform add-on): add
     a commented `ignore_changes` in the module instead of fighting it.
5. Report the drift and the proposed fix. Do not apply `refresh.tfplan` or any
   fix without explicit approval.

## Never

- Never "fix" drift by changing cloud resources with a CLI.
- Never apply a refresh-only plan to hide drift that should be investigated.
