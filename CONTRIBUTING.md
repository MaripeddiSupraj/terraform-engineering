# Contributing

Thank you for improving Terraform Engineering.

## Before opening a pull request

- Read `AGENTS.md` and `docs/terraform-standards.md`.
- Keep provider implementations separated.
- Reuse existing modules before creating another abstraction.
- Add or update tests for behavior you change.
- Run `make quality` with the tools available locally.
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

See `docs/module-authoring.md`.

## Pull request scope

Prefer one capability per pull request. A provider implementation and its unrelated documentation redesign should not be mixed unless necessary.
