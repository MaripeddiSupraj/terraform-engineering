# Skill: Plan Terraform

## Goal

Create a reviewable saved plan without applying it.

## Procedure

1. Confirm validation gates have passed.
2. Initialize the intended backend and identity context.
3. Run `terraform plan -out=tfplan`.
4. Run `terraform show -no-color tfplan` for human review.
5. Summarize add/change/destroy counts, replacements, RBAC/IAM changes, network exposure, persistent-data risks, and cost-significant resources.
6. Stop at the approval boundary.

Treat the plan as sensitive. Do not commit it.
