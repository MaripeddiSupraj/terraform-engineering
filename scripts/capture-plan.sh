#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR=${1:-.}
EVIDENCE_DIR=${2:-"${TARGET_DIR}/.evidence/$(date -u +%Y%m%dT%H%M%SZ)"}
mkdir -p "${EVIDENCE_DIR}"

PLAN_PATH="${EVIDENCE_DIR}/tfplan"

terraform -chdir="${TARGET_DIR}" plan -out="${PLAN_PATH}"
terraform -chdir="${TARGET_DIR}" show -no-color "${PLAN_PATH}" > "${EVIDENCE_DIR}/plan.txt"
terraform -chdir="${TARGET_DIR}" show -json "${PLAN_PATH}" > "${EVIDENCE_DIR}/plan.json"
terraform version -json > "${EVIDENCE_DIR}/terraform-version.json"

git rev-parse HEAD > "${EVIDENCE_DIR}/git-sha.txt" 2>/dev/null || true

cat <<EOF
Plan evidence written to: ${EVIDENCE_DIR}
WARNING: saved plan and plan JSON may contain sensitive values.
Do not commit .evidence/ to Git.
EOF
