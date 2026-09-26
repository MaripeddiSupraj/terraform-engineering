# Changelog

All notable changes are documented here. Versions follow [SemVer](https://semver.org);
while `0.x`, breaking changes bump the minor version.

## [0.2.0] - Unreleased

Agent-ready framework: guardrails in code, not only in prompts.

### Added
- Claude Code plugin + marketplace (`.claude-plugin/`), skills with frontmatter in `skills/`
  (new: `author-module`, `import-resources`, `detect-drift`).
- `scripts/guard-terraform.py`: command guard for Claude Code (`.claude/settings.json`, plugin
  `hooks/hooks.json`) and Cursor (`.cursor/hooks.json`), with tests.
- OPA/Conftest plan policies (protected destroys, public exposure, required tags, privileged IAM)
  for Azure/AWS/GCP/OCI resource types, with unit tests, fixtures and an exceptions file.
- `scripts/plan-summary.py` blast-radius summary; `capture-plan.sh` now runs the policy gate.
- Strict request schema for `azure/kubernetes-platform` and `scripts/request-to-tfvars.py`.
- AKS: user node pools (incl. spot), availability zones, auto-upgrade channels + maintenance
  window, Overlay + Cilium networking, public API requires authorized ranges, kubelet identity output.
- Network: per-subnet NSGs, delegation, rejection of internet-sourced inbound allow rules.
- Bootstrap: `prevent_destroy`, delete lock, state-writer RBAC, infrastructure encryption,
  `backend_config` output, tests.
- Negative (`expect_failures`) tests across modules; blueprint and bootstrap tests run in CI.
- Adapters: `GEMINI.md`, Cursor rules; CODEOWNERS, issue/PR templates, pre-commit, CoC.

### Changed
- CI actions pinned to commit SHAs; Conftest checksum-verified; TFLint `all` preset + azurerm ruleset;
  Dependabot for Terraform providers.
- Log Analytics disables shared-key auth by default. Key Vault has `prevent_destroy`.

### Breaking
- AKS defaults changed: Overlay + Cilium, zones 1-3, system pool tainted `CriticalAddonsOnly`,
  Azure Linux OS. Existing clusters created with 0.1 defaults would be **replaced**; pin
  `network_plugin_mode = null`, `network_data_plane = "azure"`, `availability_zones = []`,
  and `system_node_pool.only_critical_addons_enabled = false` to keep 0.1 behaviour.
- `agent/skills/` moved to `skills/`. `REPO_SETUP.md` removed.

## [0.1.0]

Initial Azure reference: resource group, network, Log Analytics, Key Vault, AKS modules,
Kubernetes platform blueprint, state bootstrap, CI quality and security gates.
