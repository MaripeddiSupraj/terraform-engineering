# Azure Key Vault

Key Vault baseline with Azure RBAC authorization, soft delete, purge
protection, default-deny network ACLs, and public network access disabled by
default. `prevent_destroy` guards against accidental deletion.

Private deployments must add a private endpoint and private DNS zone
(`privatelink.vaultcore.azure.net`); until a module for that exists here,
compose `azurerm_private_endpoint` in the blueprint.

## Usage

```hcl
module "key_vault" {
  source = "git::https://github.com/MaripeddiSupraj/terraform-engineering.git//modules/azure/key-vault?ref=v0.2.0"

  name                = "kv-payments-prod-ci"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  tags                = local.tags
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.16.3, < 2.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 5.4.0, < 6.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 5.4.0, < 6.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [azurerm_key_vault.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_allowed_ip_rules"></a> [allowed\_ip\_rules](#input\_allowed\_ip\_rules) | Public IPv4 addresses or CIDR ranges explicitly allowed by the Key Vault firewall when public network access is enabled. | `list(string)` | `[]` | no |
| <a name="input_allowed_subnet_ids"></a> [allowed\_subnet\_ids](#input\_allowed\_subnet\_ids) | Virtual network subnet resource IDs explicitly allowed by the Key Vault firewall. | `list(string)` | `[]` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region for the vault. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Globally unique Key Vault name. | `string` | n/a | yes |
| <a name="input_network_bypass"></a> [network\_bypass](#input\_network\_bypass) | Traffic allowed to bypass Key Vault network ACLs. | `string` | `"AzureServices"` | no |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | Whether the Key Vault data plane is reachable through public networking. Keep false when private connectivity is configured. | `bool` | `false` | no |
| <a name="input_purge_protection_enabled"></a> [purge\_protection\_enabled](#input\_purge\_protection\_enabled) | Enable purge protection. Once enabled, Azure does not allow it to be disabled. | `bool` | `true` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource group containing the vault. | `string` | n/a | yes |
| <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name) | Key Vault SKU. | `string` | `"standard"` | no |
| <a name="input_soft_delete_retention_days"></a> [soft\_delete\_retention\_days](#input\_soft\_delete\_retention\_days) | Soft-delete retention period. | `number` | `90` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to the vault. | `map(string)` | `{}` | no |
| <a name="input_tenant_id"></a> [tenant\_id](#input\_tenant\_id) | Microsoft Entra tenant ID used by the vault. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_id"></a> [id](#output\_id) | Key Vault resource ID. |
| <a name="output_name"></a> [name](#output\_name) | Key Vault name. |
| <a name="output_vault_uri"></a> [vault\_uri](#output\_vault\_uri) | Key Vault data-plane URI. |
<!-- END_TF_DOCS -->
