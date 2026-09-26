---
name: import-resources
description: Bring existing cloud resources under Terraform management with reviewable import blocks (never the imperative terraform import command). Use when adopting manually created or brownfield infrastructure.
---

# Import existing resources

## Procedure

1. **Discover read-only.** Use `az ... show/list`, `aws ... describe/get/list`,
   `gcloud ... describe/list` to collect resource IDs and current settings.
   Do not modify the resources.
2. **Write import blocks** next to the configuration that will own them:

   ```hcl
   import {
     to = module.network.azurerm_virtual_network.this
     id = "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<name>"
   }
   ```

   Prefer composing existing modules so imported resources match the standard.
   Use `terraform plan -generate-config-out=generated.tf` only as a starting
   point, then refactor the output into modules and delete the generated file.
3. **Plan** with the `plan-terraform` skill. The goal is a plan with the imports
   and **no** changes or replacements. Resolve every diff by adjusting the
   configuration to match reality, or call out each intentional change.
   Imports are blocked by the policy gate only if they would also destroy or
   expose something.
4. Apply only after approval (`apply-terraform`), then remove the `import`
   blocks in a follow-up change once the state is committed.

## Never

- Never run `terraform import` or `terraform state` write commands; the guard
  hook blocks them. Import blocks keep the change reviewable.
- Never accept a replacement of an imported stateful resource to "clean it up".
