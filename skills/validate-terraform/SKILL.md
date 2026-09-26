---
name: validate-terraform
description: Prove Terraform code quality before planning - fmt, init without backend, validate, native tests, TFLint and Trivy - and report exactly which checks ran. Use after any change to .tf or .tftest.hcl files and before creating a plan.
---

# Validate Terraform

## Goal

Evidence that the change is well-formed, tested and free of obvious
misconfiguration, with no cloud credentials required.

## Procedure

Run from the repository root. In this repository `make ci` runs the whole set.

```bash
terraform fmt -check -diff -recursive .
terraform -chdir=<dir> init -backend=false -input=false
terraform -chdir=<dir> validate
terraform -chdir=<dir> test              # every module/blueprint with tests/
tflint --init && tflint --chdir=<dir>    # if installed
trivy config --severity HIGH,CRITICAL . # if installed
```

Rules:

1. Run validate/test for **every** directory you changed and every blueprint
   that consumes a changed module.
2. Stop at the first failing gate. Fix the cause; do not weaken a test,
   validation, or security default to make a gate pass.
3. When you change behaviour, add or update a `run` block in `tests/`:
   one assertion for the new behaviour and, for new validations or
   preconditions, an `expect_failures` case.
4. If a tool is not installed, say "skipped: <tool> not installed". Never
   report a skipped check as passed.

## Report

```text
fmt:       pass | fail | skipped
validate:  <dirs> pass | fail
test:      <n passed>/<n total> in <dirs>
tflint:    pass | fail | skipped
trivy:     pass | fail | skipped
```
