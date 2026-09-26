#!/usr/bin/env python3
"""Validate an infrastructure request and render blueprint tfvars JSON.

  request-to-tfvars.py request.yaml                 # print terraform.tfvars.json
  request-to-tfvars.py request.yaml -o path.json    # write it
  request-to-tfvars.py --check request.yaml         # validate only

Requires: pip install pyyaml jsonschema
Exit codes: 0 ok, 1 invalid request, 2 usage/tooling error.
"""
import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCHEMA = ROOT / "schemas" / "infrastructure-request.schema.json"

# Short, stable name tokens. Extend as needed; requests may also set region_short.
AZURE_REGION_SHORT = {
    "centralindia": "ci", "southindia": "si", "westindia": "wi",
    "eastus": "eus", "eastus2": "eus2", "westus2": "wus2", "westus3": "wus3", "centralus": "cus",
    "northeurope": "neu", "westeurope": "weu", "uksouth": "uks", "swedencentral": "sec",
    "germanywestcentral": "gwc", "francecentral": "frc",
    "southeastasia": "sea", "eastasia": "ea", "japaneast": "jpe", "australiaeast": "aue",
    "canadacentral": "cac", "brazilsouth": "brs", "uaenorth": "uan",
}

RENDERERS = {}


def renderer(provider, blueprint, target):
    def register(fn):
        RENDERERS[(provider, blueprint)] = (fn, target)
        return fn
    return register


def pool(p, defaults=None):
    out = dict(defaults or {})
    mapping = {"vm_size": "vm_size", "min_nodes": "min_count", "max_nodes": "max_count",
               "node_count": "node_count", "spot": "spot", "labels": "node_labels", "taints": "node_taints"}
    for src, dst in mapping.items():
        if src in p:
            out[dst] = p[src]
    return out


def check_pool(name, p, errors):
    lo, hi = p.get("min_count"), p.get("max_count")
    if lo is not None and hi is not None and lo > hi:
        errors.append(f"{name}: min_nodes ({lo}) is greater than max_nodes ({hi})")
    n = p.get("node_count")
    if n is not None and ((lo is not None and n < lo) or (hi is not None and n > hi)):
        errors.append(f"{name}: node_count ({n}) is outside min/max nodes")


@renderer("azure", "kubernetes-platform", "blueprints/kubernetes-platform/azure")
def azure_kubernetes_platform(req, errors):
    k8s = req.get("requirements", {}).get("kubernetes", {})
    mon = req.get("requirements", {}).get("monitoring", {})
    sec = req["security"]

    region_short = req.get("region_short") or AZURE_REGION_SHORT.get(req["region"])
    if not region_short:
        errors.append(f"region_short is required for region '{req['region']}' (no built-in short name)")

    private = k8s.get("private_cluster", True)
    if not private and not sec.get("public_control_plane_allowed", False):
        errors.append("requirements.kubernetes.private_cluster is false but security.public_control_plane_allowed is not true")
    if not private and not k8s.get("api_server_authorized_ip_ranges"):
        errors.append("a public control plane requires requirements.kubernetes.api_server_authorized_ip_ranges")

    tfvars = {
        "project": req["project"],
        "environment": req["environment"],
        "location": req["region"],
        "location_short": region_short,
        "address_space": req["network"]["address_space"],
        "aks_subnet_prefixes": req["network"]["subnets"]["aks"],
        "private_cluster_enabled": private,
        "aks_admin_group_object_ids": sec["aks_admin_group_object_ids"],
        "tags": req["tags"],
    }

    system = pool(k8s.get("system_pool", {}))
    if "autoscaling" in k8s:
        system.update(pool(k8s["autoscaling"]))
    if system:
        check_pool("system_pool", system, errors)
        tfvars["system_node_pool"] = system

    if "user_pools" in k8s:
        users = {name: pool(p) for name, p in k8s["user_pools"].items()}
        for name, p in users.items():
            check_pool(f"user_pools.{name}", p, errors)
        tfvars["user_node_pools"] = users

    optional = {
        "kubernetes_version": k8s.get("version"),
        "api_server_authorized_ip_ranges": k8s.get("api_server_authorized_ip_ranges"),
        "availability_zones": k8s.get("availability_zones"),
        "maintenance_window": k8s.get("maintenance_window"),
        "log_retention_days": mon.get("retention_days"),
    }
    tfvars.update({k: v for k, v in optional.items() if v is not None})
    return tfvars


def load(path):
    text = Path(path).read_text(encoding="utf-8")
    if path.endswith(".json"):
        return json.loads(text)
    try:
        import yaml
    except ImportError:
        sys.exit("request-to-tfvars: pyyaml is required for YAML requests (pip install pyyaml)")
    return yaml.safe_load(text)


def validate_schema(req):
    try:
        import jsonschema
    except ImportError:
        print("request-to-tfvars: jsonschema is required (pip install jsonschema)", file=sys.stderr)
        sys.exit(2)
    schema = json.loads(SCHEMA.read_text(encoding="utf-8"))
    validator = jsonschema.Draft202012Validator(schema)
    return [
        f"{'/'.join(str(p) for p in e.absolute_path) or '<root>'}: {e.message}"
        for e in sorted(validator.iter_errors(req), key=lambda e: list(e.absolute_path))
    ]


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("request")
    parser.add_argument("--check", action="store_true", help="validate only")
    parser.add_argument("-o", "--output", help="write tfvars JSON to this path")
    args = parser.parse_args()

    req = load(args.request)
    errors = validate_schema(req)
    key = (req.get("provider"), req.get("blueprint")) if isinstance(req, dict) else (None, None)

    tfvars, target = None, None
    if not errors:
        if key not in RENDERERS:
            errors.append(f"no implemented blueprint for provider={key[0]} blueprint={key[1]} (see docs/capability-matrix.md)")
        else:
            fn, target = RENDERERS[key]
            tfvars = fn(req, errors)

    if errors:
        print(f"{args.request}: INVALID", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        return 1

    if args.check:
        print(f"{args.request}: valid -> {target}")
        return 0

    rendered = json.dumps(tfvars, indent=2) + "\n"
    if args.output:
        Path(args.output).write_text(rendered, encoding="utf-8")
        print(f"wrote {args.output} (target blueprint: {target})", file=sys.stderr)
    else:
        sys.stdout.write(rendered)
    return 0


if __name__ == "__main__":
    sys.exit(main())
