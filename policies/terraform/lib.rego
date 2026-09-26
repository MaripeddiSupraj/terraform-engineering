# Shared helpers for plan policies. Input is `terraform show -json <planfile>`.
package main

import rego.v1

# Managed resources the plan will touch (data sources and no-ops excluded).
changes contains rc if {
	some rc in input.resource_changes
	rc.mode == "managed"
	not rc.change.actions == ["no-op"]
	not rc.change.actions == ["read"]
}

is_delete(rc) if "delete" in rc.change.actions

is_replace(rc) if {
	"delete" in rc.change.actions
	"create" in rc.change.actions
}

writes(rc) if {
	some action in rc.change.actions
	action in {"create", "update"}
}

verb(rc) := "replace" if is_replace(rc)

verb(rc) := "destroy" if {
	is_delete(rc)
	not is_replace(rc)
}

after(rc) := object.get(rc.change, "after", {})

# Reviewed exceptions come from a data file passed with --data, for example
# .terraform-policy-exceptions.yaml in the consuming repository:
#
#   exceptions:
#     allow_destroy: ["module.old.azurerm_storage_account.this"]
#     allow_public: []
#     allow_privileged_rbac: []
#   policy:
#     required_tags: ["environment", "managed-by", "owner"]
default exceptions := {}

exceptions := data.exceptions

excepted(kind, address) if address in object.get(exceptions, kind, [])

default policy_settings := {}

policy_settings := data.policy
