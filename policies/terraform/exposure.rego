# Public network exposure must be explicit and reviewed, never a side effect.
package main

import rego.v1

open_sources := {"*", "0.0.0.0/0", "::/0", "Internet", "Any", "any"}

deny contains msg if {
	some rc in changes
	writes(rc)
	after(rc).public_network_access_enabled == true
	not excepted("allow_public", rc.address)
	msg := sprintf("%s: public_network_access_enabled = true. Use private endpoints, or add the address to exceptions.allow_public.", [rc.address])
}

deny contains msg if {
	some rc in changes
	writes(rc)
	rc.type == "azurerm_storage_account"
	after(rc).allow_nested_items_to_be_public == true
	msg := sprintf("%s: allow_nested_items_to_be_public = true permits anonymous blob access.", [rc.address])
}

deny contains msg if {
	some rc in changes
	writes(rc)
	rc.type == "azurerm_kubernetes_cluster"
	after(rc).private_cluster_enabled == false
	count(aks_authorized_ranges(rc)) == 0
	not excepted("allow_public", rc.address)
	msg := sprintf("%s: public AKS API server with no authorized_ip_ranges.", [rc.address])
}

aks_authorized_ranges(rc) := ranges if {
	some profile in object.get(after(rc), "api_server_access_profile", [])
	ranges := object.get(profile, "authorized_ip_ranges", [])
} else := []

# Azure NSG inline rules and standalone rules.
nsg_rules(rc) := object.get(after(rc), "security_rule", []) if rc.type == "azurerm_network_security_group"

nsg_rules(rc) := [after(rc)] if rc.type == "azurerm_network_security_rule"

nsg_sources(rule) := array.concat(
	[object.get(rule, "source_address_prefix", "")],
	object.get(rule, "source_address_prefixes", []),
)

deny contains msg if {
	some rc in changes
	writes(rc)
	rc.type in {"azurerm_network_security_group", "azurerm_network_security_rule"}
	some rule in nsg_rules(rc)
	rule.direction == "Inbound"
	rule.access == "Allow"
	some source in nsg_sources(rule)
	source in open_sources
	not excepted("allow_public", rc.address)
	msg := sprintf("%s: inbound Allow rule %q is open to %s.", [rc.address, rule.name, source])
}

# AWS security groups.
deny contains msg if {
	some rc in changes
	writes(rc)
	rc.type == "aws_security_group"
	some rule in object.get(after(rc), "ingress", [])
	some cidr in array.concat(object.get(rule, "cidr_blocks", []), object.get(rule, "ipv6_cidr_blocks", []))
	cidr in open_sources
	not excepted("allow_public", rc.address)
	msg := sprintf("%s: ingress from %s.", [rc.address, cidr])
}

deny contains msg if {
	some rc in changes
	writes(rc)
	rc.type == "aws_vpc_security_group_ingress_rule"
	some cidr in [object.get(after(rc), "cidr_ipv4", ""), object.get(after(rc), "cidr_ipv6", "")]
	cidr in open_sources
	not excepted("allow_public", rc.address)
	msg := sprintf("%s: ingress from %s.", [rc.address, cidr])
}

deny contains msg if {
	some rc in changes
	writes(rc)
	rc.type == "aws_s3_bucket_public_access_block"
	some setting in ["block_public_acls", "block_public_policy", "ignore_public_acls", "restrict_public_buckets"]
	object.get(after(rc), setting, true) == false
	not excepted("allow_public", rc.address)
	msg := sprintf("%s: %s = false.", [rc.address, setting])
}

# GCP firewall.
deny contains msg if {
	some rc in changes
	writes(rc)
	rc.type == "google_compute_firewall"
	object.get(after(rc), "direction", "INGRESS") == "INGRESS"
	count(object.get(after(rc), "allow", [])) > 0
	some cidr in object.get(after(rc), "source_ranges", [])
	cidr in open_sources
	not excepted("allow_public", rc.address)
	msg := sprintf("%s: ingress firewall allows %s.", [rc.address, cidr])
}
