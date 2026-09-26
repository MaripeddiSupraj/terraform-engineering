#!/usr/bin/env python3
"""Block dangerous Terraform and cloud CLI commands before an agent runs them.

Works as:
  * a Claude Code PreToolUse hook  (stdin: {"tool_input": {"command": ...}})
  * a Cursor beforeShellExecution hook (stdin: {"command": ...})
  * a plain CLI check: guard-terraform.py -- terraform apply -auto-approve

Exit 0 = allowed, exit 2 = blocked (reason on stderr; Cursor-style JSON on stdout).
Humans can disable the guard for their own session with TF_GUARD_DISABLE=1 in
the environment that launches the agent. The agent cannot set it for itself
because hooks do not inherit variables from the commands they inspect.
"""
import json
import os
import re
import shlex
import sys

TF_BINARIES = {"terraform", "tofu", "terragrunt"}
CLOUD_CLIS = {"az", "aws", "gcloud", "oci"}
DESTRUCTIVE_CLOUD_VERBS = re.compile(r"^(delete|purge|remove|destroy|terminate|rb|rm)([-_].*)?$")

APPLY_HELP = "Create a saved plan (scripts/capture-plan.sh <dir>), get explicit human approval, then run `terraform apply <planfile>`."


def reason_for_terraform(args):
    """Return a block reason for one terraform/tofu invocation, or None."""
    # Skip global options such as -chdir=... to find the subcommand.
    rest = list(args)
    while rest and rest[0].startswith("-"):
        rest.pop(0)
    if not rest:
        return None
    sub, sub_args = rest[0], rest[1:]
    flags = [a for a in sub_args if a.startswith("-")]
    positionals = [a for a in sub_args if not a.startswith("-")]

    if any(f == "-lock=false" for f in flags):
        return "`-lock=false` disables state locking and risks state corruption."
    if sub == "run-all":  # terragrunt
        return reason_for_terraform(sub_args)
    if sub == "destroy":
        return "`terraform destroy` is never run by an agent. Remove resources in code, plan, and get approval for the reviewed plan."
    if sub == "apply":
        if any(f.startswith("-auto-approve") for f in flags):
            return "`-auto-approve` bypasses the human approval boundary. " + APPLY_HELP
        if "-destroy" in flags:
            return "`apply -destroy` is a destroy. " + APPLY_HELP
        if not positionals:
            return "`terraform apply` must apply a saved, reviewed plan file. " + APPLY_HELP
        return None
    if sub == "state" and positionals and positionals[0] in {"rm", "mv", "push", "replace-provider"}:
        return f"`terraform state {positionals[0]}` edits state directly. Use `removed`/`moved`/`import` blocks in code so the change is reviewed in a plan."
    if sub == "force-unlock":
        return "`force-unlock` can corrupt state if another run holds the lock. A human must confirm no run is active and do this themselves."
    if sub == "import":
        return "Use an `import {}` block in configuration so the import is reviewed in a plan, instead of the imperative `terraform import`."
    if sub in {"taint", "untaint"}:
        return f"`terraform {sub}` is deprecated. Use `terraform plan -replace=<address>` so the replacement is reviewed."
    if sub == "workspace" and positionals and positionals[0] == "delete":
        return "Deleting a workspace can orphan its state. A human must do this."
    return None


def reason_for_cloud_cli(binary, args):
    for token in args:
        if token.startswith("-"):
            continue
        if DESTRUCTIVE_CLOUD_VERBS.match(token):
            return (
                f"`{binary} ... {token}` mutates cloud resources outside Terraform. Cloud CLIs are for read-only "
                "discovery; change infrastructure through Terraform plans."
            )
    return None


SEGMENT_SPLIT = re.compile(r"\|\||&&|;|\||\n|\$\(|`|\)")


def inspect(command, depth=0):
    if depth > 3:
        return None
    for segment in SEGMENT_SPLIT.split(command):
        segment = segment.strip()
        if not segment:
            continue
        try:
            tokens = shlex.split(segment)
        except ValueError:
            # Unbalanced quoting: fall back to a conservative text match.
            if re.search(r"\b(terraform|tofu|terragrunt)\b.*(-auto-approve|\sdestroy\b)", segment):
                return "Could not parse the command safely and it appears to auto-approve or destroy."
            tokens = segment.split()
        for i, token in enumerate(tokens):
            name = os.path.basename(token)
            if name in TF_BINARIES:
                reason = reason_for_terraform(tokens[i + 1:])
                if reason:
                    return reason
                break
            if name in CLOUD_CLIS:
                reason = reason_for_cloud_cli(name, tokens[i + 1:])
                if reason:
                    return reason
                break
            # Nested shells: bash -c "terraform destroy", eval "...".
            if " " in token and i > 0 and (tokens[i - 1] == "-c" or tokens[0] == "eval"):
                reason = inspect(token, depth + 1)
                if reason:
                    return reason
    return None


def read_command(argv):
    if len(argv) > 1:
        args = argv[1:]
        if args[0] == "--":
            args = args[1:]
        return " ".join(shlex.quote(a) for a in args)
    raw = sys.stdin.read()
    if not raw.strip():
        return ""
    try:
        payload = json.loads(raw)
    except json.JSONDecodeError:
        return raw
    tool_input = payload.get("tool_input") or {}
    return tool_input.get("command") or payload.get("command") or ""


def main():
    if os.environ.get("TF_GUARD_DISABLE") == "1":
        return 0
    command = read_command(sys.argv)
    reason = inspect(command)
    if not reason:
        return 0
    message = f"Blocked by terraform-engineering guard: {reason}"
    print(message, file=sys.stderr)
    print(json.dumps({"permission": "deny", "user_message": message, "agent_message": message}))
    return 2


if __name__ == "__main__":
    sys.exit(main())
