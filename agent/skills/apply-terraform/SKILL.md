# Skill: Apply Terraform

## Goal

Apply only the exact saved plan explicitly approved by a human.

## Preconditions

- Validation passed.
- A saved plan exists.
- The human explicitly authorized apply.
- The execution identity and target environment are confirmed.

## Procedure

Run:

```bash
terraform apply tfplan
```

Never substitute `terraform apply -auto-approve`.

After apply, verify expected outputs and provider health. Report any partial failure; do not automatically retry destructive operations.
