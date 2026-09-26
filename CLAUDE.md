# Claude Code adapter

Read and obey `AGENTS.md` first. It is the authoritative operating contract.

- Skills are in `skills/` (also exposed as `.claude/skills/`). Use them for
  design, validation, planning, apply, module authoring, import and drift.
- `.claude/settings.json` enables the `scripts/guard-terraform.py` PreToolUse
  hook and asks before any `terraform apply`. Do not edit it to weaken it.
- If the guard blocks a command, follow the reason it prints. Do not try an
  equivalent command to get around it.

Keep this file thin. Do not duplicate architecture here or weaken repository rules.
