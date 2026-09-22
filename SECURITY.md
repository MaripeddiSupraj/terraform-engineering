# Security Policy

## Reporting

Do not open a public issue containing credentials, Terraform state, saved plan files, kubeconfigs, private endpoints, subscription/account identifiers that are not already public, or sensitive production topology.

Use the repository owner's private security reporting channel once configured in GitHub.

## Repository security rules

- No cloud access keys, client secrets, passwords, or private keys in Git.
- CI authentication should use OIDC/workload federation and short-lived credentials.
- `.tfstate`, `.tfplan`, `.terraform/`, and `.evidence/` are ignored.
- Sensitive values must not be exposed as Terraform outputs for convenience.
- Saved plans and plan JSON may contain sensitive values and must be handled as sensitive artifacts.
- Production applies require an explicit approval boundary outside automatic pull-request checks.

See `docs/security-model.md` for the full model.
