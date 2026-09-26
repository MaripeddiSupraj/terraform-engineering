---
name: author-module
description: Create or change a reusable Terraform module to this framework's standard - typed and validated inputs, secure defaults, safe outputs, native tests with mock providers, and docs. Use when no existing module fits a design, or when modifying a module under modules/.
---

# Author a Terraform module

Read `docs/terraform-standards.md` and `docs/module-authoring.md` first, and
open one existing module (for example `modules/azure/network`) as the pattern.

## Layout

```text
modules/<provider>/<capability>/
  main.tf  variables.tf  outputs.tf  versions.tf  README.md
  tests/basic.tftest.hcl
```

## Checklist

1. **Scope**: one cohesive capability (`network`, `aks`, `key-vault`). No
   provider switch, no one-resource wrapper without policy value.
2. **versions.tf**: `required_version = ">= 1.16.3, < 2.0.0"` and a provider
   range (for example `>= 5.4.0, < 6.0.0`). No `provider` block in modules.
3. **Verify the provider schema** for every argument you use against the
   official provider docs for the pinned version. Do not rely on memory.
4. **Inputs**: explicit `type` and `description` on every variable; `optional()`
   object attributes with safe defaults; `validation` for anything Terraform can
   check locally (names, CIDRs, enums, ranges, GUIDs).
5. **Secure defaults**: private networking, managed identity/RBAC, encryption,
   deletion protection. Public exposure only through an explicit input, and a
   precondition that requires it to be restricted.
6. **Identity**: `for_each` with stable keys, never `count` for things with
   identity. `lifecycle.ignore_changes` only for attributes owned by something
   else (for example autoscaler node counts), with a comment explaining why.
7. **Outputs**: IDs, names, endpoints needed for composition. Never keys,
   passwords, kubeconfigs, or tokens.
8. **Tests** (`mock_provider`, `command = plan`): assert each secure default and
   add an `expect_failures` run for each validation/precondition. Give mocked
   resources valid IDs with `mock_resource ... defaults` when other resources
   consume them.
9. **Docs**: README with purpose, security defaults, a minimal example, and
   known constraints; run `make docs` to refresh the inputs/outputs tables.
10. Add the module to `docs/capability-matrix.md` only when code, tests and docs
    all exist. Then run the `validate-terraform` skill.
