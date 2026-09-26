#!/usr/bin/env bash
# Create a saved plan plus review evidence, then run the plan policy gate.
#
#   scripts/capture-plan.sh <terraform-root-dir> [evidence-dir] [-- extra plan args]
#
# Examples:
#   scripts/capture-plan.sh blueprints/kubernetes-platform/azure
#   scripts/capture-plan.sh infra -- -destroy                 # reviewed teardown plan
#   scripts/capture-plan.sh infra -- -replace=module.aks.azurerm_kubernetes_cluster.this
#
# Writes (outside Git; .evidence/ is ignored):
#   tfplan               saved plan to apply after approval
#   plan.txt / plan.json human and machine readable plan
#   summary.md           add/change/destroy counts and risky changes
#   policy.txt           policy gate output
#   terraform-version.json, git-sha.txt
#
# Exit codes: 0 = plan created and policies passed, 1 = plan or policy failure.
set -euo pipefail

FRAMEWORK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR=${1:-.}
[[ $# -gt 0 ]] && shift
EVIDENCE_DIR=""
if [[ $# -gt 0 && "$1" != "--" ]]; then
  EVIDENCE_DIR="$1"
  shift
fi
[[ "${1:-}" == "--" ]] && shift
EXTRA_PLAN_ARGS=("$@")
EVIDENCE_DIR=${EVIDENCE_DIR:-"${TARGET_DIR}/.evidence/$(date -u +%Y%m%dT%H%M%SZ)"}
mkdir -p "${EVIDENCE_DIR}"
EVIDENCE_DIR="$(cd "${EVIDENCE_DIR}" && pwd)"

# Self-ignoring evidence: repositories using this framework as a plugin may not
# ignore .evidence/, and a saved plan can contain secrets. A "*" .gitignore
# keeps the directory out of `git add -A` wherever it lives.
printf '*\n' >"${EVIDENCE_DIR}/.gitignore"
if [[ "$(basename "$(dirname "${EVIDENCE_DIR}")")" == ".evidence" ]]; then
  printf '*\n' >"$(dirname "${EVIDENCE_DIR}")/.gitignore"
fi

PLAN_PATH="${EVIDENCE_DIR}/tfplan"

# -detailed-exitcode: 0 = no changes, 2 = changes present, 1 = error.
set +e
terraform -chdir="${TARGET_DIR}" plan -input=false -lock-timeout=5m -detailed-exitcode ${EXTRA_PLAN_ARGS[@]+"${EXTRA_PLAN_ARGS[@]}"} -out="${PLAN_PATH}"
plan_rc=$?
set -e
if [[ ${plan_rc} -eq 1 ]]; then
  echo "terraform plan failed." >&2
  exit 1
fi

terraform -chdir="${TARGET_DIR}" show -no-color "${PLAN_PATH}" >"${EVIDENCE_DIR}/plan.txt"
terraform -chdir="${TARGET_DIR}" show -json "${PLAN_PATH}" >"${EVIDENCE_DIR}/plan.json"
terraform version -json >"${EVIDENCE_DIR}/terraform-version.json"
git -C "${TARGET_DIR}" rev-parse HEAD >"${EVIDENCE_DIR}/git-sha.txt" 2>/dev/null || true

python3 "${FRAMEWORK_ROOT}/scripts/plan-summary.py" "${EVIDENCE_DIR}/plan.json" | tee "${EVIDENCE_DIR}/summary.md"

set +e
"${FRAMEWORK_ROOT}/scripts/policy-check.sh" "${EVIDENCE_DIR}/plan.json" "${TARGET_DIR}" 2>&1 | tee "${EVIDENCE_DIR}/policy.txt"
policy_rc=${PIPESTATUS[0]}
set -e

cat <<EOF

Plan evidence: ${EVIDENCE_DIR}
Saved plan:    ${PLAN_PATH}
WARNING: the saved plan and plan JSON may contain sensitive values. Never commit .evidence/.
EOF

case ${policy_rc} in
  0) echo "Policy gate: PASSED. Stop here for human approval before: terraform -chdir=${TARGET_DIR} apply ${PLAN_PATH}" ;;
  2) echo "Policy gate: NOT EVALUATED (tooling missing). Report this; do not claim policies passed." ;;
  *) echo "Policy gate: FAILED. Fix the configuration or record a reviewed exception. Do not apply."; exit 1 ;;
esac
