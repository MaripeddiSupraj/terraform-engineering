# Azure Log Analytics

Log Analytics workspace with an explicit retention period (30-730 days) and
shared-key (local) authentication disabled, so ingestion and queries use
Microsoft Entra ID.

## Usage

```hcl
module "monitoring" {
  source = "git::https://github.com/MaripeddiSupraj/terraform-engineering.git//modules/azure/log-analytics?ref=v0.2.0"

  name                = "log-payments-prod-ci"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  retention_in_days   = 90
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
| [azurerm_log_analytics_workspace.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_local_authentication_enabled"></a> [local\_authentication\_enabled](#input\_local\_authentication\_enabled) | Allow shared-key (local) authentication in addition to Microsoft Entra ID. Keep false unless a legacy agent requires workspace keys. | `bool` | `false` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region for the workspace. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Log Analytics workspace name. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource group containing the workspace. | `string` | n/a | yes |
| <a name="input_retention_in_days"></a> [retention\_in\_days](#input\_retention\_in\_days) | Workspace log retention period in days. | `number` | `30` | no |
| <a name="input_sku"></a> [sku](#input\_sku) | Log Analytics workspace SKU. | `string` | `"PerGB2018"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to the workspace. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_id"></a> [id](#output\_id) | Log Analytics workspace resource ID. |
| <a name="output_workspace_id"></a> [workspace\_id](#output\_workspace\_id) | Log Analytics workspace ID used by Azure integrations. |
<!-- END_TF_DOCS -->
