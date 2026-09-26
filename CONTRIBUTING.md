# Contributing

Thank you for improving Terraform Engineering.

## Before opening a pull request

- Read `AGENTS.md` and `docs/terraform-standards.md`.
- Keep provider implementations separated.
- Reuse existing modules before creating another abstraction.
- Add or update tests for behavior you change.
- Run `make ci` (and `make security` if Trivy is installed). Say which tools you skipped.
- `pip install pre-commit && pre-commit install` runs fmt/validate/tflint/docs/gitleaks on commit.
- Do not commit generated state, plans, evidence, credentials, or provider caches.

## Module requirements

Every reusable module must have:

- `README.md`
- `main.tf`
- `variables.tf`
- `outputs.tf`
- `versions.tf`
- `tests/` with at least one Terraform test
- typed and documented inputs
- meaningful outputs that do not expose secrets

See `docs/module-authoring.md` and `skills/author-module/SKILL.md`.

## Policies, guard and skills

- Policy rules (`policies/terraform/`) need a passing and a failing unit test.
- Guard changes (`scripts/guard-terraform.py`) need cases in `tests/test_guard.py`,
  both blocked and allowed, so the guard does not become noisy.
- Skills (`skills/<name>/SKILL.md`) need `name` and `description` frontmatter; the
  description decides when an agent uses the skill, so make it specific.

## Releases

Modules are consumed with `?ref=vX.Y.Z`. Breaking input/behaviour changes bump the
minor version while `0.x`, and are listed under **Breaking** in `CHANGELOG.md`.

## Pull request scope

Prefer one capability per pull request. A provider implementation and its unrelated documentation redesign should not be mixed unless necessary.
