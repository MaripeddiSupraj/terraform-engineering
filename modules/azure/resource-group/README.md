# Azure Resource Group

Minimal resource-group foundation used by higher-level blueprints. Naming is
provided by the caller so enterprise naming policy stays at the composition layer.

## Usage

```hcl
module "resource_group" {
  source = "git::https://github.com/MaripeddiSupraj/terraform-engineering.git//modules/azure/resource-group?ref=v0.2.0"

  name     = "rg-payments-prod-ci"
  location = "centralindia"
  tags     = local.tags
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
| [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_location"></a> [location](#input\_location) | Azure region used by resources in the group. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name of the Azure resource group. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to the resource group. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_id"></a> [id](#output\_id) | Resource group resource ID. |
| <a name="output_location"></a> [location](#output\_location) | Resource group Azure region. |
| <a name="output_name"></a> [name](#output\_name) | Resource group name. |
| <a name="output_tags"></a> [tags](#output\_tags) | Tags applied to the resource group, for callers that verify tag propagation. |
<!-- END_TF_DOCS -->
