# Agentic Terraform Workflow

## Phase 1 — Understand

Normalize provider, environment, region, capability, compliance/security constraints, availability requirements, and expected scale. Do not infer production-sensitive defaults silently.

## Phase 2 — Design

Select an existing blueprint if possible. Identify approved modules and provider-native dependencies. Call out any new module required before writing it.

## Phase 3 — Implement

Make the smallest composable change. Keep naming, tags, and security defaults consistent.

## Phase 4 — Prove quality

Run the checks that are available and report exact results. A model statement such as "this should work" is not evidence.

## Phase 5 — Plan

Create a saved Terraform plan. Summarize add/change/destroy counts, replacements, public exposure changes, IAM/RBAC changes, database/storage destruction risk, and known cost-impacting resources.

## Phase 6 — Approve

Human approval applies to the exact reviewed saved plan. A changed configuration requires a new plan.

## Phase 7 — Apply and verify

Apply the saved plan, verify expected resources/endpoints/health, and capture evidence in a non-Git location.
