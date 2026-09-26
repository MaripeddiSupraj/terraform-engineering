#!/usr/bin/env bash
# Evaluate a Terraform plan (JSON) against the framework plan policies.
#
#   scripts/policy-check.sh <plan.json> [terraform-root-dir]
#
# Exceptions are read from the first file found:
#   $POLICY_EXCEPTIONS
#   <terraform-root-dir>/.terraform-policy-exceptions.yaml
#   <repository-root>/.terraform-policy-exceptions.yaml (current git repo)
#
# Exit codes: 0 = pass (warnings allowed), 1 = policy violations, 2 = usage/tool error.
set -euo pipefail

FRAMEWORK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
POLICY_DIR="${POLICY_DIR:-${FRAMEWORK_ROOT}/policies/terraform}"

PLAN_JSON="${1:-}"
TF_ROOT="${2:-.}"

if [[ -z "${PLAN_JSON}" || ! -f "${PLAN_JSON}" ]]; then
  echo "usage: $(basename "$0") <plan.json> [terraform-root-dir]" >&2
  exit 2
fi

if ! command -v conftest >/dev/null 2>&1; then
  echo "policy-check: conftest is not installed (https://www.conftest.dev). Policy gate NOT evaluated." >&2
  exit 2
fi

data_args=()
candidates=("${POLICY_EXCEPTIONS:-}" "${TF_ROOT}/.terraform-policy-exceptions.yaml")
if git_root="$(git -C "${TF_ROOT}" rev-parse --show-toplevel 2>/dev/null)"; then
  candidates+=("${git_root}/.terraform-policy-exceptions.yaml")
fi
for candidate in "${candidates[@]}"; do
  if [[ -n "${candidate}" && -f "${candidate}" ]]; then
    echo "policy-check: using exceptions from ${candidate}"
    data_args=(--data "${candidate}")
    break
  fi
done

exec conftest test --no-color --policy "${POLICY_DIR}" "${data_args[@]}" "${PLAN_JSON}"
