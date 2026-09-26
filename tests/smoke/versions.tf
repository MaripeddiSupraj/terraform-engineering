# Cloud-free smoke root for the plan -> policy -> approve -> apply workflow.
# Uses only the built-in terraform_data resource, so it needs no provider
# download and no credentials. Exercised by tests/smoke/run.sh and CI.
terraform {
  required_version = ">= 1.6.0"
}
