# Plan policies

The policy gate evaluates the **saved plan** (`terraform show -json tfplan`) with
[Conftest](https://www.conftest.dev)/OPA before anything is applied. Policies see
the final resolved values, including values that come from modules, variables,
and defaults, which static HCL scanners cannot.

```bash
scripts/policy-check.sh .evidence/<ts>/plan.json <terraform-root>
# or, end to end (plan + summary + policies):
scripts/capture-plan.sh <terraform-root>
```

| Rule | Level | File |
|---|---|---|
| Destroy/replace of stateful or foundational resources (storage, vaults, databases, clusters, networks, KMS …) | deny | `terraform/destroy.rego` |
| Any other destroy/replace | warn | `terraform/destroy.rego` |
| `public_network_access_enabled = true`, anonymous blob access, public AKS API without authorized ranges | deny | `terraform/exposure.rego` |
| Inbound allow from `*`/`0.0.0.0/0`/`Internet` (Azure NSG, AWS SG, GCP firewall), S3 public-access-block disabled | deny | `terraform/exposure.rego` |
| Missing required tags (`environment`, `managed-by` by default) on taggable resources | deny | `terraform/tags.rego` |
| Owner / User Access Administrator / RBAC Administrator assignments, AWS `*:*` policies, GCP owner/editor | deny | `terraform/iam.rego` |
| Role assignment at subscription or management-group scope | warn | `terraform/iam.rego` |

Rules cover Azure, AWS, GCP and OCI resource types, so the gate is useful for
any Terraform root, not only the reference modules in this repository.

## Exceptions

Exceptions are data, not code changes to the policies. Copy
[`exceptions.example.yaml`](exceptions.example.yaml) to
`.terraform-policy-exceptions.yaml` in the Terraform root (or repository root)
and list full resource addresses. `policy.required_tags` overrides the required
tag set. Treat edits to that file like any other security-relevant change.

`bootstrap/azure/.terraform-policy-exceptions.yaml` is a worked example.

## Testing

```bash
make policy-test   # conftest verify + fixture plans (one passing, one violating)
```

Every rule has unit tests in `terraform/policy_test.rego`. New rules need a
passing and a failing test case.
