# Security Model

## Identity first

Local developers may authenticate through the cloud CLI. CI/CD should use short-lived identity federation (for example GitHub OIDC) instead of stored cloud access keys.

## State is sensitive

Terraform state can contain data that is not safe to publish. Remote state must use encrypted storage, access controls, versioning/recovery controls where available, and a narrow CI identity.

## Plans are sensitive too

A saved plan or `terraform show -json` output can contain sensitive operational data. Keep generated evidence outside Git and restrict retention/access.

## Defaults

Provider modules should default toward private access and managed identity when it is practical. A public endpoint must be an explicit input and documented at the blueprint layer.

## CI boundary

Pull-request checks may format, initialize, validate, test, lint, and statically scan without cloud credentials. Cloud planning should run only in an identity-enabled workflow. Apply should sit behind an explicit environment approval boundary.

## Secrets

Never store:

- cloud client secrets;
- access keys;
- passwords;
- private keys;
- kubeconfigs;
- state encryption keys;
- storage account keys;
- sensitive tfvars.
