#!/usr/bin/env python3
"""Summarize a Terraform plan JSON for human approval.

Usage: plan-summary.py <plan.json>

Prints Markdown with action counts and the changes a reviewer must look at
first: destroys/replacements, IAM/RBAC, network exposure and data stores.
Uses only the Python standard library.
"""
import json
import sys
from collections import Counter

IAM_HINTS = ("role_assignment", "iam_", "_iam", "role_definition", "policy_attachment")
NETWORK_HINTS = ("security_group", "security_rule", "firewall", "public_ip", "route", "network_rule", "_nsg")
DATA_HINTS = (
    "storage_account", "storage_container", "s3_bucket", "storage_bucket", "key_vault", "kms",
    "sql", "postgres", "mysql", "cosmos", "dynamodb", "rds", "redis", "disk", "volume", "database",
    "objectstorage",
)


def action_label(actions):
    if actions == ["no-op"] or actions == ["read"]:
        return None
    if "delete" in actions and "create" in actions:
        return "replace"
    if actions == ["delete"]:
        return "destroy"
    if actions == ["create"]:
        return "create"
    if actions == ["update"]:
        return "update"
    return "+".join(actions)


def main(path):
    with open(path, encoding="utf-8") as fh:
        plan = json.load(fh)

    counts = Counter()
    risky = {"Destroy / replace": [], "IAM / RBAC": [], "Network exposure": [], "Data stores": []}

    for rc in plan.get("resource_changes", []):
        if rc.get("mode") != "managed":
            continue
        label = action_label(rc["change"]["actions"])
        if label is None:
            continue
        counts[label] += 1
        entry = f"`{rc['address']}` ({label})"
        rtype = rc["type"]
        if label in ("destroy", "replace"):
            risky["Destroy / replace"].append(entry)
        if any(h in rtype for h in IAM_HINTS):
            risky["IAM / RBAC"].append(entry)
        if any(h in rtype for h in NETWORK_HINTS):
            risky["Network exposure"].append(entry)
        if any(h in rtype for h in DATA_HINTS):
            risky["Data stores"].append(entry)

    drift = [r["address"] for r in plan.get("resource_drift", []) if r.get("change", {}).get("actions") != ["no-op"]]

    print("## Terraform plan summary\n")
    print(f"- Terraform: {plan.get('terraform_version', 'unknown')}")
    total = sum(counts.values())
    if total == 0:
        print("- **No changes.** Infrastructure matches configuration.")
    else:
        parts = [f"{counts[k]} to {k}" for k in ("create", "update", "replace", "destroy") if counts[k]]
        parts += [f"{v} {k}" for k, v in counts.items() if k not in ("create", "update", "replace", "destroy")]
        print(f"- Changes: {', '.join(parts)}")
    if drift:
        print(f"- Drift detected outside Terraform: {len(drift)} resource(s)")

    for title, items in risky.items():
        if items:
            print(f"\n### {title} ({len(items)})\n")
            for item in sorted(set(items)):
                print(f"- {item}")

    if counts["destroy"] or counts["replace"]:
        print("\n> **Review required:** this plan destroys or replaces resources.")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("usage: plan-summary.py <plan.json>")
    main(sys.argv[1])
