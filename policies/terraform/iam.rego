# Least privilege: no tenant/subscription-owner style grants and no wildcard
# IAM from Terraform without a reviewed exception.
package main

import rego.v1

privileged_azure_roles := {"Owner", "User Access Administrator", "Role Based Access Control Administrator"}

deny contains msg if {
	some rc in changes
	writes(rc)
	rc.type == "azurerm_role_assignment"
	after(rc).role_definition_name in privileged_azure_roles
	not excepted("allow_privileged_rbac", rc.address)
	msg := sprintf("%s: assigns privileged role %q. Grant a narrower role, or add the address to exceptions.allow_privileged_rbac.", [rc.address, after(rc).role_definition_name])
}

warn contains msg if {
	some rc in changes
	writes(rc)
	rc.type == "azurerm_role_assignment"
	scope := object.get(after(rc), "scope", "")
	is_string(scope)
	regex.match(`^(/|/subscriptions/[^/]+/?|/providers/Microsoft.Management/managementGroups/[^/]+/?)$`, scope)
	msg := sprintf("%s: role assignment at subscription or management-group scope (%s). Prefer resource-group or resource scope.", [rc.address, scope])
}

aws_policy_types := {"aws_iam_policy", "aws_iam_role_policy", "aws_iam_user_policy", "aws_iam_group_policy"}

as_array(x) := x if is_array(x)

as_array(x) := [x] if not is_array(x)

deny contains msg if {
	some rc in changes
	writes(rc)
	rc.type in aws_policy_types
	doc := json.unmarshal(after(rc).policy)
	some stmt in as_array(doc.Statement)
	stmt.Effect == "Allow"
	"*" in as_array(object.get(stmt, "Action", []))
	"*" in as_array(object.get(stmt, "Resource", []))
	not excepted("allow_privileged_rbac", rc.address)
	msg := sprintf("%s: IAM policy allows Action \"*\" on Resource \"*\".", [rc.address])
}

gcp_iam_types := {
	"google_project_iam_member", "google_project_iam_binding",
	"google_organization_iam_member", "google_organization_iam_binding",
	"google_folder_iam_member", "google_folder_iam_binding",
}

deny contains msg if {
	some rc in changes
	writes(rc)
	rc.type in gcp_iam_types
	after(rc).role in {"roles/owner", "roles/editor"}
	not excepted("allow_privileged_rbac", rc.address)
	msg := sprintf("%s: grants primitive role %s.", [rc.address, after(rc).role])
}
