## What and why

<!-- One or two sentences. Link the issue if there is one. -->

## Checks

- [ ] `make ci` passes locally (or list what was skipped and why)
- [ ] New/changed behaviour has a Terraform test (`run` block), including `expect_failures` for new validations
- [ ] New/changed policy rules have a passing and a failing test in `policies/terraform/policy_test.rego`
- [ ] Module READMEs regenerated (`make docs`) if inputs/outputs changed
- [ ] No credentials, state, plans, or `.evidence/` committed
- [ ] Security defaults are not weakened; any public exposure is explicit and restricted

## Blast radius

<!-- For module changes: which blueprints are affected, and would existing deployments see replacements? -->
