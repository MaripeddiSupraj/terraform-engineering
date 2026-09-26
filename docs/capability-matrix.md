# Capability Matrix

Legend: **implemented** = code + docs + tests exist in this repository.
**planned** = contract/roadmap only.

## Provider modules and blueprints

| Capability | Azure | AWS | GCP | OCI |
|---|---|---|---|---|
| Resource-group/project foundation | implemented | planned | planned | planned |
| Network (+ per-subnet NSG / security groups) | implemented | planned | planned | planned |
| Central logging workspace | implemented | planned | planned | planned |
| Secret vault baseline | implemented | planned | planned | planned |
| Managed Kubernetes module (system + user pools) | implemented | planned | planned | planned |
| Kubernetes platform blueprint | implemented | planned | planned | planned |
| Remote-state bootstrap | implemented | planned | planned | planned |
| Request contract + tfvars renderer | implemented | planned | planned | planned |
| Managed database | planned | planned | planned | planned |
| Private endpoints/DNS bundle | planned | planned | planned | planned |
| Ingress / application gateway | planned | planned | planned | planned |

## Provider-neutral framework

These work with any Terraform code, including providers without modules here.

| Capability | Status |
|---|---|
| Agent operating contract (`AGENTS.md`) and adapters (Claude, Cursor, Copilot, Gemini) | implemented |
| Skills: design, validate, plan, apply, author-module, import, drift | implemented |
| Command guard hook (Claude Code, Cursor, CLI) | implemented |
| Claude Code plugin + marketplace | implemented |
| Plan policy gate (destroy, exposure, tags, IAM) for Azure/AWS/GCP/OCI resource types | implemented |
| Plan evidence capture + blast-radius summary | implemented |
| CI quality gates (fmt, validate, test, TFLint, Trivy, Gitleaks, policy, schema) | implemented |
| CI cloud plan with OIDC + PR comment | planned |
| Controlled apply workflow (environment approval) | planned |
| Scheduled drift detection | planned |
| Cost policy gate | planned |

Do not change **planned** to **implemented** until the capability meets the
same code/test/documentation bar as the Azure reference.
