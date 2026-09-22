# Policy Packs

This directory defines the policy boundary for the framework.

Initial enforcement lives in module defaults, Terraform variable validation, pull-request quality checks, and IaC security scanning. Future provider-neutral plan policies will inspect Terraform plan JSON for rules such as:

- unapproved public exposure;
- missing required ownership/environment tags;
- destructive changes to persistent data;
- wildcard IAM/RBAC grants;
- unencrypted storage;
- production SKU/HA requirements;
- cost thresholds.

Policy engines must consume saved-plan output and must not require agents to mutate cloud resources directly.
