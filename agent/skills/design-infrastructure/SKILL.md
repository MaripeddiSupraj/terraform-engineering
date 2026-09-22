# Skill: Design Infrastructure

## Goal

Turn a human infrastructure request into a reviewable provider-native design before writing Terraform.

## Procedure

1. Identify provider, environment, region, blueprint/capability, scale, availability, networking, identity, data, and observability requirements.
2. Inspect `docs/capability-matrix.md` and the target provider modules.
3. Prefer an existing blueprint and modules.
4. State unresolved assumptions that materially affect cost, security, or topology.
5. Produce a compact design listing modules, dependencies, security boundaries, and expected outputs.
6. Do not mutate infrastructure in this skill.
