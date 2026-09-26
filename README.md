# Terraform Engineering

**Guardrails, skills and reviewed modules that let AI coding agents write and
operate Terraform safely.**

Give an agent (Claude Code, Codex, Cursor, Copilot, Gemini CLI) a request like
*"create a private production AKS platform in Central India"*. It follows a
fixed workflow: design, compose reviewed modules, validate, create a saved plan,
pass a policy gate, then **stop for human approval**. The dangerous parts are
enforced by code, not by the prompt:

- a **guard hook** blocks `terraform destroy`, `apply -auto-approve`, `apply`
  without a saved plan, state surgery, and destructive cloud CLI calls;
- an **OPA plan-policy gate** rejects protected-resource destroys, public
  exposure, missing tags and privileged IAM **in the actual plan**;
- **input validation and tests** in every module reject insecure configurations
  at plan time.

> **Status:** Azure is the reference implementation (AKS platform, network,
> Key Vault, Log Analytics, state bootstrap). The guard, skills and plan policies
> work with **any** Terraform code, including AWS, GCP and OCI.
> AWS/GCP/OCI modules are on the roadmap. See the
> [capability matrix](docs/capability-matrix.md).

## How it works

```text
 "private AKS in centralindia, 3-6 system nodes, workload identity"
        │
        ▼
 design-infrastructure ── request contract (schema) ── human approves design
        │
        ▼
 compose reviewed modules (modules/azure/*, blueprints/*)
        │
        ▼
 validate-terraform ── fmt · validate · test · tflint · trivy
        │
        ▼
 plan-terraform ── saved plan ── OPA policy gate ── blast-radius summary
        │
        ▼
 ██ human approval of that exact plan ██   ← guard hook blocks every shortcut
        │
        ▼
 apply-terraform ── apply saved plan ── verify ── no drift
```

## Quick start

### Claude Code (plugin: use the guardrails in any repo)

```text
/plugin marketplace add MaripeddiSupraj/terraform-engineering
/plugin install terraform-engineering@terraform-engineering
```

This adds 7 skills (`design-infrastructure`, `validate-terraform`,
`plan-terraform`, `apply-terraform`, `author-module`, `import-resources`,
`detect-drift`) and the guard hook to every session. For the policy gate, install
[Conftest](https://www.conftest.dev).

### Working inside this repository (any agent)

```bash
git clone https://github.com/MaripeddiSupraj/terraform-engineering
cd terraform-engineering
```

| Agent | What loads automatically |
|---|---|
| Claude Code | `CLAUDE.md` → `AGENTS.md`, skills in `.claude/skills/`, guard hook + apply approval prompt in `.claude/settings.json` |
| Cursor | `.cursor/rules/`, guard hook in `.cursor/hooks.json` |
| Codex / others | `AGENTS.md` + `skills/` |
| GitHub Copilot | `.github/copilot-instructions.md` |
| Gemini CLI | `GEMINI.md` |

Then ask for what you need:

```text
Create a production Azure Kubernetes platform in Central India. Private
networking, three system nodes autoscaling to six, an apps pool, workload
identity, Azure Monitor, and no credentials in Terraform.
```

### Without an agent

```bash
az login
python3 scripts/request-to-tfvars.py examples/requests/azure-aks.yaml \
  -o blueprints/kubernetes-platform/azure/terraform.tfvars.json
cd blueprints/kubernetes-platform/azure
cp backend.tf.example backend.tf      # after bootstrap/azure; fill in values
terraform init && terraform test
../../../scripts/capture-plan.sh .    # plan + evidence + policy gate
terraform apply .evidence/<timestamp>/tfplan
```

## What's in the box

| Path | Purpose |
|---|---|
| [`AGENTS.md`](AGENTS.md) | Authoritative operating contract for every agent |
| [`skills/`](skills) | Step-by-step procedures (Agent Skills format) |
| [`scripts/guard-terraform.py`](scripts/guard-terraform.py) | Command guard for Claude Code / Cursor hooks or CLI use |
| [`policies/`](policies) | OPA/Conftest rules evaluated on the saved plan, with unit tests and an exceptions file |
| [`scripts/capture-plan.sh`](scripts/capture-plan.sh) | Saved plan + JSON + summary + policy gate as evidence (outside Git) |
| [`schemas/`](schemas) + [`scripts/request-to-tfvars.py`](scripts/request-to-tfvars.py) | Strict request contract; renders validated tfvars for a blueprint |
| [`modules/azure/`](modules/azure) | Reviewed modules: resource group, network (+NSGs), Log Analytics, Key Vault, AKS |
| [`blueprints/kubernetes-platform/azure`](blueprints/kubernetes-platform/azure) | Composed, tested AKS platform |
| [`bootstrap/azure`](bootstrap/azure) | Hardened remote-state storage (Entra-only, locked, versioned) |
| [`.claude-plugin/`](.claude-plugin) + [`hooks/`](hooks) | Claude Code plugin + marketplace manifest |

## Azure reference defaults

- **AKS:** private API server, Entra ID + Azure RBAC, local accounts off,
  workload identity, Azure CNI Overlay + Cilium, zones 1-3, a system pool tainted
  for critical add-ons plus user pools, autoscaler-owned node counts (no drift),
  patch auto-upgrades in a maintenance window, Standard SLA tier.
- **Network:** one NSG per subnet, no implicit internet egress, internet-sourced
  inbound allow rules rejected.
- **Key Vault:** RBAC, purge protection, default-deny firewall, no public access,
  `prevent_destroy`.
- **State:** no shared keys, infrastructure encryption, versioning + soft delete,
  delete lock, RBAC for pipeline identities.

## Development

```bash
make help        # all targets
make ci          # fmt, validate, test, tflint, policy tests, guard tests, schema checks
make security    # trivy
make docs        # regenerate module input/output tables
```

Requirements: Terraform 1.16.3 (AzureRM 5.4.0 for the Azure reference), plus
TFLint, Conftest, Trivy, terraform-docs and Python 3.10+ (`pip install -r requirements.txt`)
for the full set.

## Non-goals

- Pretending all clouds are identical or hiding them behind a mega-module.
- Letting an agent change production without an approval boundary.
- Storing credentials, state, or plans in Git.
- Marking a provider supported before its modules, tests, docs and blueprint
  meet the Azure bar.

## Roadmap

1. Azure: private endpoints + private DNS, Application Gateway/ingress,
   PostgreSQL Flexible Server, user-assigned identity modules.
2. GitHub Actions reference pipeline: OIDC plan on PR (plan + policy as a PR
   comment), environment-protected apply of the saved plan artifact.
3. AWS (EKS), GCP (GKE) and OCI (OKE) reference blueprints.
4. Cost gate (Infracost) and scheduled drift detection.

## Contributing and security

Read [CONTRIBUTING.md](CONTRIBUTING.md). Report vulnerabilities privately, see
[SECURITY.md](SECURITY.md). Never post state files, plans, or credentials in
issues.

## License

MIT. See [LICENSE](LICENSE).
