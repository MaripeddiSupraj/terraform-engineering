# Terraform Standards

## File structure

Reusable modules use:

- `main.tf`
- `variables.tf`
- `outputs.tf`
- `versions.tf`
- `README.md`
- `tests/*.tftest.hcl`

Use `locals.tf` only when locals materially improve readability.

## Inputs

- Every variable has an explicit type and description.
- Prefer objects/maps over parallel variable lists.
- Add validation for constraints Terraform can verify locally.
- Secret inputs are marked sensitive, but remember that `sensitive = true` is display redaction—not a guarantee that a value is absent from state.

## Outputs

Expose stable IDs, names, endpoints, and metadata needed for composition. Do not output credentials, kubeconfigs, passwords, access tokens, or private key material.

## Resources

- Use stable `for_each` keys where resource identity matters.
- Avoid provisioners and `null_resource` orchestration.
- Avoid unnecessary explicit dependencies.
- Use lifecycle rules only for a documented reason.
- Public ingress/access must be explicit, not a convenience default.

## Versions

Reusable modules declare tested compatibility ranges. Root blueprints and CI pin versions tightly enough for reproducible validation.

## Comments

Bad:

```hcl
# Create a virtual network
resource "azurerm_virtual_network" "this" {
```

Useful:

```hcl
# The platform keeps application and private-endpoint address spaces separate
# so future hub/spoke routing changes do not require renumbering workloads.
```

Explain decisions, constraints, or non-obvious behavior—not syntax.
