package main

import rego.v1

rc(address, type, actions, after) := {
	"address": address,
	"mode": "managed",
	"type": type,
	"change": {"actions": actions, "before": {}, "after": after, "after_unknown": {}},
}

plan(changes) := {"resource_changes": changes}

good_tags := {"environment": "prod", "managed-by": "terraform"}

# ---- destroy -------------------------------------------------------------

test_protected_destroy_denied if {
	count(deny) == 1 with input as plan([rc("azurerm_storage_account.state", "azurerm_storage_account", ["delete"], null)])
}

test_protected_replace_denied if {
	some msg in deny with input as plan([rc("azurerm_kubernetes_cluster.this", "azurerm_kubernetes_cluster", ["delete", "create"], {"tags": good_tags})])
	contains(msg, "replace")
}

test_protected_destroy_allowed_by_exception if {
	count(deny) == 0 with input as plan([rc("azurerm_storage_account.old", "azurerm_storage_account", ["delete"], null)])
		with data.exceptions as {"allow_destroy": ["azurerm_storage_account.old"]}
}

test_unprotected_destroy_only_warns if {
	p := plan([rc("azurerm_subnet.this[\"aks\"]", "azurerm_subnet", ["delete"], null)])
	count(deny) == 0 with input as p
	count(warn) == 1 with input as p
}

test_noop_ignored if {
	count(deny) == 0 with input as plan([rc("azurerm_storage_account.state", "azurerm_storage_account", ["no-op"], {"tags": {}})])
}

# ---- exposure ------------------------------------------------------------

test_public_network_access_denied if {
	count(deny) == 1 with input as plan([rc("azurerm_key_vault.this", "azurerm_key_vault", ["create"], {"public_network_access_enabled": true, "tags": good_tags})])
}

test_public_network_access_exception if {
	count(deny) == 0 with input as plan([rc("azurerm_storage_account.state", "azurerm_storage_account", ["create"], {"public_network_access_enabled": true, "tags": good_tags})])
		with data.exceptions as {"allow_public": ["azurerm_storage_account.state"]}
}

test_public_aks_without_ranges_denied if {
	count(deny) == 1 with input as plan([rc("azurerm_kubernetes_cluster.this", "azurerm_kubernetes_cluster", ["create"], {"private_cluster_enabled": false, "api_server_access_profile": [], "tags": good_tags})])
}

test_public_aks_with_ranges_allowed if {
	count(deny) == 0 with input as plan([rc("azurerm_kubernetes_cluster.this", "azurerm_kubernetes_cluster", ["create"], {"private_cluster_enabled": false, "api_server_access_profile": [{"authorized_ip_ranges": ["198.51.100.0/24"]}], "tags": good_tags})])
}

test_nsg_internet_inbound_denied if {
	rule := {"name": "allow-ssh", "direction": "Inbound", "access": "Allow", "source_address_prefix": "Internet", "source_address_prefixes": []}
	count(deny) == 1 with input as plan([rc("azurerm_network_security_group.this", "azurerm_network_security_group", ["create"], {"security_rule": [rule], "tags": good_tags})])
}

test_nsg_private_inbound_allowed if {
	rule := {"name": "allow-vnet", "direction": "Inbound", "access": "Allow", "source_address_prefix": "", "source_address_prefixes": ["10.0.0.0/8"]}
	count(deny) == 0 with input as plan([rc("azurerm_network_security_group.this", "azurerm_network_security_group", ["create"], {"security_rule": [rule], "tags": good_tags})])
}

test_aws_open_security_group_denied if {
	count(deny) == 1 with input as plan([rc("aws_security_group.web", "aws_security_group", ["create"], {"ingress": [{"cidr_blocks": ["0.0.0.0/0"]}], "tags_all": good_tags})])
}

test_gcp_open_firewall_denied if {
	count(deny) == 1 with input as plan([rc("google_compute_firewall.ssh", "google_compute_firewall", ["create"], {"direction": "INGRESS", "allow": [{"protocol": "tcp"}], "source_ranges": ["0.0.0.0/0"], "effective_labels": good_tags})])
}

# ---- tags ----------------------------------------------------------------

test_missing_tags_denied if {
	some msg in deny with input as plan([rc("azurerm_resource_group.this", "azurerm_resource_group", ["create"], {"tags": {"environment": "prod"}})])
	contains(msg, "managed-by")
}

test_null_tags_denied if {
	count(deny) == 1 with input as plan([rc("azurerm_resource_group.this", "azurerm_resource_group", ["create"], {"tags": null})])
}

test_untaggable_resource_ignored if {
	count(deny) == 0 with input as plan([rc("azurerm_subnet.this", "azurerm_subnet", ["create"], {"name": "aks"})])
}

test_required_tags_configurable if {
	count(deny) == 1 with input as plan([rc("azurerm_resource_group.this", "azurerm_resource_group", ["create"], {"tags": good_tags})])
		with data.policy as {"required_tags": ["owner"]}
}

test_unknown_tags_skipped if {
	change := {"actions": ["create"], "after": {}, "after_unknown": {"tags_all": true}}
	count(deny) == 0 with input as plan([{"address": "aws_s3_bucket.b", "mode": "managed", "type": "aws_s3_bucket", "change": change}])
}

# ---- iam -----------------------------------------------------------------

test_owner_role_denied if {
	count(deny) == 1 with input as plan([rc("azurerm_role_assignment.ci", "azurerm_role_assignment", ["create"], {"role_definition_name": "Owner", "scope": "/subscriptions/0000/resourceGroups/rg"})])
}

test_subscription_scope_warns if {
	p := plan([rc("azurerm_role_assignment.ci", "azurerm_role_assignment", ["create"], {"role_definition_name": "Reader", "scope": "/subscriptions/0000"})])
	count(deny) == 0 with input as p
	count(warn) == 1 with input as p
}

test_aws_wildcard_policy_denied if {
	doc := json.marshal({"Version": "2012-10-17", "Statement": [{"Effect": "Allow", "Action": "*", "Resource": "*"}]})
	count(deny) == 1 with input as plan([rc("aws_iam_policy.admin", "aws_iam_policy", ["create"], {"policy": doc, "tags_all": good_tags})])
}

test_aws_scoped_policy_allowed if {
	doc := json.marshal({"Version": "2012-10-17", "Statement": [{"Effect": "Allow", "Action": ["s3:GetObject"], "Resource": "arn:aws:s3:::b/*"}]})
	count(deny) == 0 with input as plan([rc("aws_iam_policy.read", "aws_iam_policy", ["create"], {"policy": doc, "tags_all": good_tags})])
}

test_gcp_owner_denied if {
	count(deny) == 1 with input as plan([rc("google_project_iam_member.x", "google_project_iam_member", ["create"], {"role": "roles/owner"})])
}
