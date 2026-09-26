# Azure Terraform State Bootstrap

Creates the storage used by an `azurerm` remote backend: a resource group, a
zone-redundant storage account, and a private container.

## Protections

- Entra ID only: shared keys, local users and SAS are disabled; `default_to_oauth_authentication`.
- Infrastructure encryption, TLS 1.2, HTTPS only, no anonymous blob access, copy scope limited to the tenant.
- Blob versioning, change feed, and blob/container soft delete (30 days by default).
- `prevent_destroy` on the account and container, plus a `CanNotDelete` management lock.
- Firewall default-deny. Public access requires explicit `allowed_ip_rules`; an empty list is rejected.
- `state_writer_principals` grants **Storage Blob Data Contributor** to the identities that run Terraform (for example a GitHub OIDC service principal).

## Bootstrap sequence

State for this root starts local because the backend does not exist yet.

```bash
cp terraform.tfvars.example terraform.tfvars   # set a globally unique name, your runner IP, state writers
terraform init
../../scripts/capture-plan.sh .                # plan + policy gate (uses .terraform-policy-exceptions.yaml here)
terraform apply .evidence/<timestamp>/tfplan   # after review
terraform output backend_config
```

`.terraform-policy-exceptions.yaml` records the one reviewed exception: the
state account is publicly reachable (behind the IP firewall) until private CI
connectivity exists. Remove it when you set `public_network_access_enabled = false`.

Optionally migrate this root's own state into the new container afterwards
(add a backend block with a `bootstrap/terraform.tfstate` key, then
`terraform init -migrate-state`).

## Using the backend

Copy `blueprints/kubernetes-platform/azure/backend.tf.example` to `backend.tf`
in each root and fill in the values from `backend_config`. `use_azuread_auth = true`
is required because account keys are disabled.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | = 1.16.3 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | = 5.4.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | = 5.4.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [azurerm_management_lock.state](https://registry.terraform.io/providers/hashicorp/azurerm/5.4.0/docs/resources/management_lock) | resource |
| [azurerm_resource_group.state](https://registry.terraform.io/providers/hashicorp/azurerm/5.4.0/docs/resources/resource_group) | resource |
| [azurerm_role_assignment.state_writers](https://registry.terraform.io/providers/hashicorp/azurerm/5.4.0/docs/resources/role_assignment) | resource |
| [azurerm_storage_account.state](https://registry.terraform.io/providers/hashicorp/azurerm/5.4.0/docs/resources/storage_account) | resource |
| [azurerm_storage_container.state](https://registry.terraform.io/providers/hashicorp/azurerm/5.4.0/docs/resources/storage_container) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_allowed_ip_rules"></a> [allowed\_ip\_rules](#input\_allowed\_ip\_rules) | Public IPv4 addresses or CIDR ranges allowed through the state storage firewall. Required when public network access is enabled. | `list(string)` | `[]` | no |
| <a name="input_container_name"></a> [container\_name](#input\_container\_name) | Blob container used for Terraform state. | `string` | `"tfstate"` | no |
| <a name="input_delete_lock_enabled"></a> [delete\_lock\_enabled](#input\_delete\_lock\_enabled) | Apply a CanNotDelete management lock to the state storage account. | `bool` | `true` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region for state infrastructure. | `string` | n/a | yes |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | Whether the state storage account is reachable from public networking. Requires allowed\_ip\_rules. Disable once private CI connectivity exists. | `bool` | `true` | no |
| <a name="input_replication_type"></a> [replication\_type](#input\_replication\_type) | Storage replication. ZRS survives a zone outage; GZRS also survives a regional outage. | `string` | `"ZRS"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource group created for Terraform remote-state infrastructure. | `string` | n/a | yes |
| <a name="input_soft_delete_retention_days"></a> [soft\_delete\_retention\_days](#input\_soft\_delete\_retention\_days) | Blob and container soft-delete retention, in days. | `number` | `30` | no |
| <a name="input_state_writer_principals"></a> [state\_writer\_principals](#input\_state\_writer\_principals) | Principals granted Storage Blob Data Contributor on the state account, keyed by a stable label (for example github-prod-plan). | <pre>map(object({<br/>    principal_id   = string<br/>    principal_type = optional(string, "ServicePrincipal")<br/>  }))</pre> | `{}` | no |
| <a name="input_storage_account_name"></a> [storage\_account\_name](#input\_storage\_account\_name) | Globally unique Azure Storage account name used for Terraform state. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to state infrastructure. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_backend_config"></a> [backend\_config](#output\_backend\_config) | Values for an azurerm backend block. Add a unique key per root module and environment. Contains no credentials. |
| <a name="output_container_name"></a> [container\_name](#output\_container\_name) | State container name. |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | State resource group name. |
| <a name="output_storage_account_name"></a> [storage\_account\_name](#output\_storage\_account\_name) | State storage account name. |
<!-- END_TF_DOCS -->
