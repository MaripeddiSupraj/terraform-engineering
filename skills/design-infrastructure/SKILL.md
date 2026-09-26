---
name: design-infrastructure
description: Turn an infrastructure request ("create a private AKS platform in Central India…") into a reviewable, provider-native Terraform design before any code is written. Use at the start of any new infrastructure, blueprint, or module request.
---

# Design infrastructure

Scripts referenced below live in this framework's `scripts/` directory:
`${CLAUDE_PLUGIN_ROOT}/scripts` when installed as a plugin, or `scripts/` at the
root of the terraform-engineering repository.

## Goal

Produce a short design a human can approve **before** Terraform is written.
No cloud mutation happens in this skill.

## Procedure

1. **Normalize the request** into the request contract
   (`schemas/infrastructure-request.schema.json`). Capture provider,
   environment, region, blueprint, scale, availability, networking, identity,
   data, observability and tags. For `azure` + `kubernetes-platform`, validate
   and render it:

   ```bash
   python3 scripts/request-to-tfvars.py --check request.yaml
   python3 scripts/request-to-tfvars.py request.yaml > blueprints/kubernetes-platform/azure/terraform.tfvars.json
   ```

2. **Check what exists.** Read `docs/capability-matrix.md`, the target
   blueprint README, and the READMEs of the modules you plan to use. Only
   capabilities marked *implemented* are available; say so plainly when the
   request needs something marked *planned*.
3. **Compose before generating.** Prefer an existing blueprint, then existing
   modules. A new module is a separate, explicitly called-out piece of work
   (see the `author-module` skill).
4. **Surface decisions that change cost, security or topology.** Ask instead of
   guessing when any of these are unspecified for a non-dev environment:
   public vs private endpoints, region/zones, CIDR ranges, admin groups,
   node sizes/counts, data retention, deletion protection.
5. **Write the design** (in the reply, not a file unless asked):

   ```text
   Provider / environment / region:
   Blueprint:
   Modules (existing | new):
   Network & exposure: (private endpoints, public ingress, CIDRs)
   Identity & access: (managed identities, RBAC groups, CI identity)
   Data & protection: (stateful resources, backup, deletion protection)
   Estimated cost drivers:
   Open questions / assumptions:
   ```

6. Stop and wait for approval of the design before implementing.

## Never

- Never infer production-sensitive defaults silently.
- Never design a provider-agnostic "mega-module" selected by a provider string.
- Never plan to put credentials, keys or kubeconfigs in Terraform or outputs.
