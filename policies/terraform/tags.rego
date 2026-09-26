# Ownership and environment tags are how cost, incident and cleanup tooling
# find the owner of a resource. Every taggable resource must carry them.
package main

import rego.v1

default_required_tags := ["environment", "managed-by"]

required_tags := object.get(policy_settings, "required_tags", default_required_tags)

# Attribute that holds effective tags, per provider.
tag_attribute(rc) := "tags" if startswith(rc.type, "azurerm_")

tag_attribute(rc) := "tags_all" if startswith(rc.type, "aws_")

tag_attribute(rc) := "effective_labels" if startswith(rc.type, "google_")

tag_attribute(rc) := "freeform_tags" if startswith(rc.type, "oci_")

deny contains msg if {
	some rc in changes
	writes(rc)
	attr := tag_attribute(rc)

	# Only resources that support tags expose the attribute in the plan.
	attr in object.keys(after(rc))

	# Skip values Terraform cannot know until apply.
	not object.get(object.get(rc.change, "after_unknown", {}), attr, false) == true
	tags := object.get(after(rc), attr, {})
	missing := [t | some t in required_tags; not t in object.keys(tag_map(tags))]
	count(missing) > 0
	msg := sprintf("%s: missing required tags %v.", [rc.address, missing])
}

tag_map(tags) := tags if is_object(tags)

tag_map(tags) := {} if not is_object(tags)
