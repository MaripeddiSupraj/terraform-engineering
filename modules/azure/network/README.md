# Azure Network

One virtual network, a map of subnets, and one NSG per subnet.

## Security defaults

- Every subnet gets an associated NSG unless `network_security_group.enabled = false`.
  With no custom rules, Azure's default rules deny inbound internet traffic.
- Inbound `Allow` rules from `*`, `0.0.0.0/0`, `Internet` or `Any` are rejected at plan time.
- `default_outbound_access_enabled = false`: egress must be explicit (load balancer, NAT gateway, firewall).
- Private endpoint network policies enabled so NSGs and routes apply to private endpoints.

The caller owns topology (hub/spoke, peering, route tables, firewalls).

## Usage

```hcl
module "network" {
  source = "git::https://github.com/MaripeddiSupraj/terraform-engineering.git//modules/azure/network?ref=v0.2.0"

  name                = "vnet-payments-prod-ci"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  address_space       = ["10.20.0.0/16"]

  subnets = {
    aks       = { address_prefixes = ["10.20.0.0/22"] }
    endpoints = { address_prefixes = ["10.20.4.0/24"] }
  }

  tags = local.tags
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
| [azurerm_network_security_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_subnet.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet_network_security_group_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_virtual_network.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_address_space"></a> [address\_space](#input\_address\_space) | CIDR ranges assigned to the virtual network. | `list(string)` | n/a | yes |
| <a name="input_dns_servers"></a> [dns\_servers](#input\_dns\_servers) | Custom DNS servers for the VNet. Empty uses Azure-provided DNS. | `list(string)` | `[]` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region for the virtual network. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Virtual network name. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource group containing the virtual network. | `string` | n/a | yes |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | Subnets keyed by stable subnet name. Each subnet gets its own NSG by default<br/>(network\_security\_group.enabled = true). Rules are keyed by rule name; an<br/>empty rule map keeps Azure's default rules, which deny inbound internet traffic. | <pre>map(object({<br/>    address_prefixes                  = list(string)<br/>    service_endpoints                 = optional(set(string), [])<br/>    default_outbound_access_enabled   = optional(bool, false)<br/>    private_endpoint_network_policies = optional(string, "Enabled")<br/>    delegation = optional(object({<br/>      name    = string<br/>      service = string<br/>      actions = optional(list(string), [])<br/>    }))<br/>    network_security_group = optional(object({<br/>      enabled = optional(bool, true)<br/>      rules = optional(map(object({<br/>        priority                     = number<br/>        direction                    = string<br/>        access                       = string<br/>        protocol                     = string<br/>        destination_port_ranges      = list(string)<br/>        source_address_prefixes      = list(string)<br/>        destination_address_prefixes = list(string)<br/>        description                  = optional(string)<br/>      })), {})<br/>    }), {})<br/>  }))</pre> | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to the virtual network and network security groups. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_id"></a> [id](#output\_id) | Virtual network resource ID. |
| <a name="output_name"></a> [name](#output\_name) | Virtual network name. |
| <a name="output_network_security_group_ids"></a> [network\_security\_group\_ids](#output\_network\_security\_group\_ids) | Network security group IDs keyed by subnet name (only subnets with an NSG). |
| <a name="output_subnet_ids"></a> [subnet\_ids](#output\_subnet\_ids) | Subnet resource IDs keyed by subnet name. |
<!-- END_TF_DOCS -->
