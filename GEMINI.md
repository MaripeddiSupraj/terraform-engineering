# Gemini CLI adapter

Read and obey `AGENTS.md` first. It is the authoritative operating contract.

Follow the procedures in `skills/*/SKILL.md` (design, validate, plan, apply,
author-module, import-resources, detect-drift). Before running any shell
command that invokes terraform/tofu or a cloud CLI, check it with:

    python3 scripts/guard-terraform.py -- <command>

Exit code 2 means the command is blocked; follow the printed reason instead.
