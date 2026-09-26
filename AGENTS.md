# Agent operating contract

This file is authoritative for every AI coding agent (Claude Code, Codex,
Cursor, Copilot, Gemini CLI, …) and every human automation operating this
repository or a repository that uses this framework.

## Mission

Create and maintain production-quality Terraform using reviewed,
provider-native modules and controlled execution. The framework must remain
usable without any specific AI vendor.

## Non-negotiable rules

1. **Read before write.** Inspect the target blueprint, module READMEs,
   versions, tests, and `docs/terraform-standards.md` before changing code.
2. **Compose before generating.** Prefer existing reviewed modules. Create a
   new module only when no appropriate module exists, and say so first.
3. **Keep providers separated.** Azure code belongs under Azure paths, AWS under
   AWS paths, and so on. Never build a multi-cloud module selected by a
   provider string.
4. **No secrets.** Never commit or output credentials, tokens, passwords, client
   secrets, private keys, kubeconfigs, `.tfstate`, saved plans, or evidence.
5. **No hidden mutation.** Cloud CLIs are read-only discovery tools. Change
   infrastructure through Terraform plans only.
6. **Terraform owns infrastructure.** Do not fix drift by changing cloud
   resources by hand. Do not edit state; use `import`, `moved`, and `removed`
   blocks so changes appear in a plan.
7. **No blind apply.** Never use `-auto-approve`, never run `apply` without a
   saved plan file, never run `terraform destroy`. Produce a saved plan, pass
   the policy gate, and stop at the approval boundary.
8. **Small changes.** Keep changes reviewable. Do not rewrite unrelated modules.
9. **Provider-native design.** Preserve cloud capabilities rather than forcing
   a lowest-common-denominator abstraction.
10. **Evidence over claims.** Report exactly what was run and what passed,
    failed, or was skipped. Never claim a check passed if it did not run.

## Enforcement (not just instructions)

| Control | What it enforces | Where |
|---|---|---|
| Guard hook | Blocks `destroy`, `apply -auto-approve`, `apply` without a plan file, `state rm/mv/push`, `force-unlock`, `import`, `taint`, `-lock=false`, and destructive cloud CLI verbs | `scripts/guard-terraform.py`, wired in `.claude/settings.json`, `hooks/hooks.json` (plugin), `.cursor/hooks.json` |
| Approval prompt | Claude Code asks the human before any `terraform apply` | `.claude/settings.json` |
| Plan policy gate | Denies protected destroys, public exposure, missing tags, privileged IAM on the saved plan | `policies/terraform/*.rego`, `scripts/policy-check.sh` |
| Input validation | Invalid names, CIDRs, enums, public endpoints without restrictions fail at plan time | module `variables.tf` validations and preconditions |
| CI gates | fmt, validate, tests, TFLint, Trivy, Gitleaks, policy tests, request-schema checks | `.github/workflows/` |

If the guard or the policy gate blocks something, follow its message. Do not
try an equivalent command, edit the guard, or add a policy exception on your
own initiative. Exceptions (`.terraform-policy-exceptions.yaml`) require the
human to state the change is intended.

## Skills

Procedures live in `skills/<name>/SKILL.md`:

| Skill | Use when |
|---|---|
| `design-infrastructure` | New request; produce a design before code |
| `author-module` | No module fits, or a module under `modules/` changes |
| `validate-terraform` | After any `.tf`/`.tftest.hcl` change |
| `plan-terraform` | Preview changes; saved plan + policy gate + blast radius |
| `apply-terraform` | Human approved a specific saved plan |
| `import-resources` | Adopting existing resources with `import` blocks |
| `detect-drift` | Checking reality against Terraform |

## Required workflow

```text
request -> design-infrastructure (human approves design)
        -> implement (compose modules / author-module)
        -> validate-terraform (fmt, validate, test, lint, security)
        -> plan-terraform (saved plan, policy gate, blast-radius report)
        -> human approval of that exact plan
        -> apply-terraform (apply the saved plan, verify, no drift)
```

## Code quality contract

- Standard files: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`,
  optional `locals.tf`, `README.md`, `tests/*.tftest.hcl`.
- Every input has an explicit type and description; add `validation` whenever
  Terraform can catch a bad value early.
- Outputs are intentional; never expose secret material for convenience.
- `for_each` with stable keys over `count` for resources with identity.
- No provisioners, no `null_resource` orchestration, no unnecessary `depends_on`.
- `lifecycle.ignore_changes` only for attributes owned by another controller,
  with a comment explaining why.
- Reusable modules declare version ranges; root blueprints pin exact versions.
- Comments explain **why**, not what the HCL already says.
- Tags/labels flow through every module; `environment` and `managed-by` are
  required by policy.

## Security contract

Reject or redesign code that:

- embeds credentials in HCL, tfvars, workflows, examples, or scripts;
- enables public access without an explicit, documented, restricted input;
- outputs passwords, private keys, kubeconfigs, or tokens;
- uses long-lived cloud keys in CI where workload identity/OIDC is available;
- commits `.terraform`, `.tfstate`, `.tfplan`, crash logs, or `.evidence`;
- disables a security control, test, or policy merely to make a gate pass.

## Provider discovery

When a version-sensitive resource or argument changes, verify it against the
official provider documentation for the pinned version before implementing.
Do not rely on remembered schemas.

## Apply boundary

A request to *write*, *review*, *fix*, *plan*, or *prepare* Terraform is not
authorization to apply it. Apply requires explicit human intent to execute a
specific reviewed plan. A changed configuration requires a new plan.

## Done means

The final report states:

- files changed;
- commands actually executed;
- checks that passed / failed / were skipped (and why);
- plan summary and policy-gate result if a plan was possible;
- remaining risks or prerequisites;
- whether any cloud mutation occurred.
