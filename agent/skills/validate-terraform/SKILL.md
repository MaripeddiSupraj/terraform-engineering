# Skill: Validate Terraform

## Goal

Prove code quality before planning.

## Procedure

Run, where applicable:

```bash
terraform fmt -check -recursive .
terraform -chdir=<target> init -backend=false -input=false
terraform -chdir=<target> validate
terraform -chdir=<module> test
```

If TFLint/Trivy are installed, run them too. Stop on failures and report the exact failing command. Never claim skipped tools passed.
