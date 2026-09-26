#!/usr/bin/env bash
# End-to-end workflow smoke test without a cloud account:
#   capture-plan (plan + JSON + summary + policy) -> guard allows saved-plan apply
#   -> apply saved plan -> no drift -> destroy shows up in summary + policy warning
#   -> guard blocks the shortcuts.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DIR="${ROOT}/tests/smoke"
WORK="$(mktemp -d)"
trap 'rm -rf "${WORK}" "${DIR}/.terraform" "${DIR}/terraform.tfstate" "${DIR}/terraform.tfstate.backup" "${DIR}/.terraform.lock.hcl"' EXIT
cd "${ROOT}"

pass() { echo "PASS: $*"; }
fail() { echo "FAIL: $*" >&2; exit 1; }

terraform -chdir="${DIR}" init -input=false >/dev/null

# 1. Create: plan + evidence + policy gate.
scripts/capture-plan.sh "${DIR}" "${WORK}/create" >"${WORK}/create.log" 2>&1 || { cat "${WORK}/create.log"; fail "capture-plan (create)"; }
grep -q "2 to create" "${WORK}/create/summary.md" || fail "summary should report 2 creates"
grep -q "Policy gate: PASSED" "${WORK}/create.log" || fail "policy gate should pass"
for f in tfplan plan.txt plan.json summary.md policy.txt terraform-version.json; do
  [[ -s "${WORK}/create/${f}" ]] || fail "missing evidence file ${f}"
done
[[ "$(cat "${WORK}/create/.gitignore")" == "*" ]] || fail "evidence directory must ignore itself"
pass "capture-plan produced evidence, passed the policy gate, and git-ignores itself"

# 2. The guard allows applying the saved plan, and blocks shortcuts.
python3 scripts/guard-terraform.py -- terraform -chdir="${DIR}" apply "${WORK}/create/tfplan" || fail "guard blocked a saved-plan apply"
for cmd in "terraform -chdir=${DIR} apply -auto-approve" "terraform -chdir=${DIR} apply" "terraform -chdir=${DIR} destroy"; do
  if python3 scripts/guard-terraform.py -- ${cmd} >/dev/null 2>&1; then fail "guard allowed: ${cmd}"; fi
done
pass "guard allows saved-plan apply and blocks auto-approve / plan-less apply / destroy"

# 3. Apply exactly the reviewed plan, then confirm no drift.
terraform -chdir="${DIR}" apply -input=false "${WORK}/create/tfplan" >/dev/null
set +e; terraform -chdir="${DIR}" plan -input=false -detailed-exitcode >/dev/null; rc=$?; set -e
[[ ${rc} -eq 0 ]] || fail "expected no changes after apply (exit ${rc})"
pass "applied saved plan; follow-up plan shows no drift"

# 4. A stale saved plan is refused after state changed.
set +e; terraform -chdir="${DIR}" apply -input=false "${WORK}/create/tfplan" >/dev/null 2>&1; rc=$?; set -e
[[ ${rc} -ne 0 ]] || fail "re-applying a stale plan should fail"
pass "stale saved plan is rejected"

# 5. Destroying a resource is surfaced in the summary and as a policy warning.
TF_VAR_cache_enabled=false scripts/capture-plan.sh "${DIR}" "${WORK}/destroy" >"${WORK}/destroy.log" 2>&1 || { cat "${WORK}/destroy.log"; fail "capture-plan (destroy)"; }
grep -q "1 to destroy" "${WORK}/destroy/summary.md" || fail "summary should report the destroy"
grep -q "Review required" "${WORK}/destroy/summary.md" || fail "summary should flag review"
grep -q "WARN.*terraform_data.cache\[0\].*destroy" "${WORK}/destroy/policy.txt" || fail "policy should warn about the destroy"
pass "destroy is flagged in summary and policy output"

# 6. Teardown goes through a reviewed destroy plan, never `terraform destroy`.
scripts/capture-plan.sh "${DIR}" "${WORK}/teardown" -- -destroy >"${WORK}/teardown.log" 2>&1 || { cat "${WORK}/teardown.log"; fail "capture-plan (teardown)"; }
grep -q "2 to destroy" "${WORK}/teardown/summary.md" || fail "teardown summary should report 2 destroys"
terraform -chdir="${DIR}" apply -input=false "${WORK}/teardown/tfplan" >/dev/null
[[ -z "$(terraform -chdir="${DIR}" state list)" ]] || fail "state should be empty after teardown"
pass "teardown via saved destroy plan leaves empty state"

echo "Smoke test passed."
