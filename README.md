# Terraform Engineering

Production-grade, **agent-neutral Terraform engineering framework** for Azure, AWS, GCP, and OCI.

The repository treats AI assistants as operators of an engineering system—not as unrestricted Terraform generators. Human intent is converted into provider-native compositions built from reviewed modules, validated through repeatable quality gates, and executed only through controlled workflows.

> **Current reference implementation:** Azure. AWS, GCP, and OCI provider trees are intentionally present as contracts/roadmap areas and must reach the same quality bar before being marked supported.

## Why this repository exists

Most "agentic DevOps" demos are prompt collections around one AI tool or one cloud. This repository takes the opposite approach:

- **Terraform-first** — infrastructure code and its contracts are the product.
- **Agent-neutral** — Claude Code, Codex, Gemini CLI, Copilot, or a human can operate the same repository.
- **Provider-native** — common workflow, separate cloud implementations. No lowest-common-denominator mega-module.
- **Module-first** — agents compose reviewed modules before generating new resources.
- **Plan-first** — no blind `apply`, no `-auto-approve` in repository workflows.
- **No long-lived secrets** — CI is expected to use OIDC/workload federation.
- **Evidence-oriented** — plan, validation, security, approval, and verification can be captured outside Git.

## Architecture

```text
Human / AI Agent
       |
       v
Infrastructure request contract
       |
       v
Architecture + approved module selection
       |
       v
Provider-native Terraform composition
       |
       v
fmt -> validate -> test -> lint -> security -> plan
       |
       v
Human approval
       |
       v
apply -> verify -> evidence
```

Provider-neutral behavior lives above the module layer. Cloud-specific implementation remains native:

```text
Kubernetes platform
  Azure -> AKS
  AWS   -> EKS
  GCP   -> GKE
  OCI   -> OKE
```

## Repository layout

```text
.
├── AGENTS.md                         # Authoritative agent operating contract
├── CLAUDE.md                         # Thin Claude adapter
├── docs/                             # Architecture and engineering standards
├── schemas/                          # Machine-readable request contracts
├── examples/requests/                # Example infrastructure requests
├── modules/
│   ├── azure/                        # Working reference modules
│   ├── aws/                          # Provider contract / roadmap
│   ├── gcp/                          # Provider contract / roadmap
│   └── oci/                          # Provider contract / roadmap
├── blueprints/
│   └── kubernetes-platform/azure/    # Working Azure composition
├── bootstrap/azure/                  # Remote-state bootstrap root module
├── agent/skills/                     # Tool-neutral operating procedures
├── policies/                         # Policy contract and future policy packs
├── scripts/                          # Quality/evidence helpers
└── .github/workflows/                # PR quality and security gates
```

## Current Azure reference

The initial reference path contains reviewed building blocks for:

- Resource groups
- Virtual networks and subnets
- Log Analytics
- AKS with managed identity, Azure RBAC, workload identity, private-cluster support, autoscaling, and monitoring
- Key Vault with RBAC authorization, purge protection, and public-network control
- Azure remote-state bootstrap
- A composed Kubernetes platform blueprint

This is deliberately a **small, high-quality foundation**, not a catalog of hundreds of generated modules.

## Prerequisites

- Terraform `1.16.3`
- AzureRM provider `5.4.0` for the current Azure reference
- Azure CLI for local Azure authentication
- Optional: TFLint and Trivy for local quality checks

## Quick start — Azure Kubernetes platform

1. Authenticate without putting credentials in this repository:

```bash
az login
az account set --subscription <subscription-id>
```

2. Copy the example variables:

```bash
cd blueprints/kubernetes-platform/azure
cp terraform.tfvars.example terraform.tfvars
```

3. Review and edit `terraform.tfvars`.

4. Initialize and validate:

```bash
terraform init
terraform fmt -check
terraform validate
terraform test
```

5. Create and inspect a saved plan:

```bash
terraform plan -out=tfplan
terraform show -no-color tfplan
```

6. Apply **only after human review**:

```bash
terraform apply tfplan
```

The repository never instructs agents to use `terraform apply -auto-approve`.

## Remote state

`bootstrap/azure` creates the Azure Storage resources required for a remote backend. Bootstrap state itself is intentionally local on the first run; follow its README, then configure the target blueprint backend using your own names.

Backend credentials must use Azure identity/OIDC—not storage account keys committed to Git.

## Using an AI coding agent

All agents must read [AGENTS.md](AGENTS.md). It is the source of truth for execution behavior. Tool-specific files are thin adapters only.

Example request:

```text
Create a production Azure Kubernetes platform in Central India.
Use private networking, three system nodes, autoscaling to six nodes,
workload identity, Azure Monitor, and no credentials in Terraform.
```

Expected agent behavior:

1. Normalize the request.
2. Identify `azure` + `kubernetes-platform`.
3. Reuse the approved Azure modules.
4. Make the smallest reviewable composition change.
5. Run formatting, validation, tests, lint/security checks where available.
6. Produce a saved Terraform plan.
7. Explain risk/blast radius.
8. Stop before apply unless the human explicitly approves execution.

## Development commands

```bash
make fmt
make validate
make test
make quality
```

## Non-goals

This project does **not**:

- pretend all cloud providers expose identical capabilities;
- hide provider-native concepts behind a universal mega-module;
- let an agent mutate production infrastructure without an approval boundary;
- store cloud credentials or secret values in Git;
- claim a provider is supported before its modules, tests, docs, and blueprint pass the same quality bar.

## Roadmap

1. Harden Azure reference modules and private connectivity.
2. Add Azure PostgreSQL, Application Gateway, private DNS, and managed identity modules.
3. Add AWS equivalents and an EKS reference blueprint.
4. Add GCP equivalents and a GKE reference blueprint.
5. Add OCI equivalents and an OKE reference blueprint.
6. Add plan-policy packs, cost gates, drift workflows, import/migration workflows, and signed evidence bundles.

See [docs/capability-matrix.md](docs/capability-matrix.md) for the honest implementation status.

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md) and [docs/module-authoring.md](docs/module-authoring.md). New modules must include documentation, typed inputs, useful outputs, tests, and no embedded credentials.

## Security

Read [SECURITY.md](SECURITY.md) and [docs/security-model.md](docs/security-model.md). Never open a public issue containing credentials, state files, Terraform plan files, or sensitive infrastructure data.

## License

MIT. See [LICENSE](LICENSE).
