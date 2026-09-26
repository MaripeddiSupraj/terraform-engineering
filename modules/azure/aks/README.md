# Azure Kubernetes Service

Opinionated, production-leaning AKS baseline. Application workloads run on
`user_node_pools`; the system pool is reserved for critical add-ons.

## Security and operability defaults

- Private API server by default. A public API server requires
  `api_server_authorized_ip_ranges` (0.0.0.0/0 is rejected).
- Microsoft Entra ID + Azure RBAC; local accounts disabled; at least one admin group required.
- OIDC issuer + Workload Identity enabled; Azure Policy add-on enabled.
- Azure CNI Overlay with the Cilium data plane and network policy.
- Node pools span zones 1-3; autoscaling on every pool. The autoscaler owns
  `node_count`, which Terraform ignores after creation to avoid drift.
- Automatic patch upgrades and node-image updates inside a weekly maintenance window.
- Standard (SLA) control-plane tier; Azure Linux node OS.
- Spot user pools get the AKS spot taint automatically.
- No kubeconfig or credentials are output. Grant `AcrPull` to `kubelet_identity_object_id`.

## Usage

```hcl
module "aks" {
  source = "git::https://github.com/MaripeddiSupraj/terraform-engineering.git//modules/azure/aks?ref=v0.2.0"

  name                   = "aks-payments-prod-ci"
  resource_group_name    = "rg-payments-prod-ci"
  location               = "centralindia"
  dns_prefix             = "aks-payments-prod-ci"
  subnet_id              = module.network.subnet_ids["aks"]
  admin_group_object_ids = ["<entra-group-object-id>"]

  user_node_pools = {
    apps = { vm_size = "Standard_D8ds_v5", min_count = 2, max_count = 10 }
  }

  log_analytics_workspace_id = module.monitoring.id
  tags                       = local.tags
}
```

## Constraints

- Changing `vm_size`, `zones`, `max_pods`, `os_disk_size_gb` on a pool
  rotates it through `temporary_name_for_rotation`; nodes are replaced.
- Changing `network_plugin_mode` or `network_data_plane` on an existing cluster
  can force replacement. Check the plan.
- Pin `kubernetes_version` in production after checking regional support
  (`az aks get-versions --location <region>`).

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
| [azurerm_kubernetes_cluster.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster) | resource |
| [azurerm_kubernetes_cluster_node_pool.user](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster_node_pool) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_admin_group_object_ids"></a> [admin\_group\_object\_ids](#input\_admin\_group\_object\_ids) | Microsoft Entra group object IDs granted AKS admin access through Azure RBAC. | `list(string)` | n/a | yes |
| <a name="input_api_server_authorized_ip_ranges"></a> [api\_server\_authorized\_ip\_ranges](#input\_api\_server\_authorized\_ip\_ranges) | CIDRs allowed to reach a public API server. Required when private\_cluster\_enabled is false; ignored otherwise. | `list(string)` | `[]` | no |
| <a name="input_automatic_upgrade_channel"></a> [automatic\_upgrade\_channel](#input\_automatic\_upgrade\_channel) | Cluster auto-upgrade channel. patch keeps the minor version pinned while applying supported patches. Null disables auto-upgrade. | `string` | `"patch"` | no |
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | Availability zones for node pools. Set to [] only in regions without zone support. | `list(string)` | <pre>[<br/>  "1",<br/>  "2",<br/>  "3"<br/>]</pre> | no |
| <a name="input_dns_prefix"></a> [dns\_prefix](#input\_dns\_prefix) | DNS prefix assigned to the AKS cluster. | `string` | n/a | yes |
| <a name="input_dns_service_ip"></a> [dns\_service\_ip](#input\_dns\_service\_ip) | kube-dns service IP inside service\_cidr. Set together with service\_cidr. | `string` | `null` | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | AKS Kubernetes version. Set explicitly in production after checking versions supported in the target Azure region. Null lets Azure select its current default. | `string` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region for the AKS cluster. | `string` | n/a | yes |
| <a name="input_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#input\_log\_analytics\_workspace\_id) | Optional Log Analytics workspace resource ID used by the AKS monitoring agent. | `string` | `null` | no |
| <a name="input_maintenance_window"></a> [maintenance\_window](#input\_maintenance\_window) | Weekly planned-maintenance window applied to both cluster auto-upgrades and node OS upgrades. Null lets AKS upgrade at any time. | <pre>object({<br/>    day_of_week    = optional(string, "Sunday")<br/>    start_time     = optional(string, "02:00")<br/>    utc_offset     = optional(string, "+00:00")<br/>    duration_hours = optional(number, 4)<br/>  })</pre> | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | AKS cluster name. | `string` | n/a | yes |
| <a name="input_network_data_plane"></a> [network\_data\_plane](#input\_network\_data\_plane) | AKS network data plane. cilium also selects Cilium network policy; azure selects Azure network policy. | `string` | `"cilium"` | no |
| <a name="input_network_plugin_mode"></a> [network\_plugin\_mode](#input\_network\_plugin\_mode) | Azure CNI mode. overlay (recommended) keeps pod IPs out of the VNet; null uses flat Azure CNI where pods consume subnet IPs. | `string` | `"overlay"` | no |
| <a name="input_node_os_upgrade_channel"></a> [node\_os\_upgrade\_channel](#input\_node\_os\_upgrade\_channel) | Node OS image upgrade channel. | `string` | `"NodeImage"` | no |
| <a name="input_outbound_type"></a> [outbound\_type](#input\_outbound\_type) | AKS outbound routing mode. Production hub/spoke designs typically use userDefinedRouting through a firewall or a NAT gateway. | `string` | `"loadBalancer"` | no |
| <a name="input_pod_cidr"></a> [pod\_cidr](#input\_pod\_cidr) | Pod CIDR used in overlay mode. Must not overlap the VNet, peered networks, or service\_cidr. | `string` | `"192.168.0.0/16"` | no |
| <a name="input_private_cluster_enabled"></a> [private\_cluster\_enabled](#input\_private\_cluster\_enabled) | Whether the Kubernetes API server uses private-cluster mode. | `bool` | `true` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource group containing the AKS cluster. | `string` | n/a | yes |
| <a name="input_service_cidr"></a> [service\_cidr](#input\_service\_cidr) | Kubernetes service CIDR. Null uses the AKS default. Must not overlap the VNet or pod\_cidr. | `string` | `null` | no |
| <a name="input_sku_tier"></a> [sku\_tier](#input\_sku\_tier) | AKS control-plane SKU tier. Standard includes the uptime SLA and is the production default. | `string` | `"Standard"` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Subnet resource ID used by the system node pool and, unless overridden, by user node pools. | `string` | n/a | yes |
| <a name="input_system_node_pool"></a> [system\_node\_pool](#input\_system\_node\_pool) | System node-pool sizing, autoscaling and isolation configuration. | <pre>object({<br/>    name                         = optional(string, "system")<br/>    temporary_name_for_rotation  = optional(string, "systemtmp")<br/>    vm_size                      = optional(string, "Standard_D4ds_v5")<br/>    node_count                   = optional(number, 3)<br/>    min_count                    = optional(number, 3)<br/>    max_count                    = optional(number, 6)<br/>    max_pods                     = optional(number, 110)<br/>    os_disk_size_gb              = optional(number, 128)<br/>    os_sku                       = optional(string, "AzureLinux")<br/>    only_critical_addons_enabled = optional(bool, true)<br/>    max_surge                    = optional(string, "33%")<br/>  })</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to the AKS cluster and its node pools. | `map(string)` | `{}` | no |
| <a name="input_user_node_pools"></a> [user\_node\_pools](#input\_user\_node\_pools) | User node pools keyed by pool name (1-12 lowercase alphanumeric). Each pool autoscales; set spot = true for interruptible capacity. | <pre>map(object({<br/>    vm_size                     = optional(string, "Standard_D4ds_v5")<br/>    temporary_name_for_rotation = optional(string)<br/>    node_count                  = optional(number, 2)<br/>    min_count                   = optional(number, 2)<br/>    max_count                   = optional(number, 10)<br/>    max_pods                    = optional(number, 110)<br/>    os_disk_size_gb             = optional(number, 128)<br/>    os_sku                      = optional(string, "AzureLinux")<br/>    subnet_id                   = optional(string)<br/>    zones                       = optional(list(string))<br/>    node_labels                 = optional(map(string), {})<br/>    node_taints                 = optional(list(string), [])<br/>    spot                        = optional(bool, false)<br/>    max_surge                   = optional(string, "33%")<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_id"></a> [id](#output\_id) | AKS cluster resource ID. |
| <a name="output_kubelet_identity_object_id"></a> [kubelet\_identity\_object\_id](#output\_kubelet\_identity\_object\_id) | Object ID of the kubelet managed identity. Grant AcrPull on container registries to this identity. |
| <a name="output_name"></a> [name](#output\_name) | AKS cluster name. |
| <a name="output_node_resource_group"></a> [node\_resource\_group](#output\_node\_resource\_group) | Name of the AKS-managed node resource group. |
| <a name="output_oidc_issuer_url"></a> [oidc\_issuer\_url](#output\_oidc\_issuer\_url) | OIDC issuer URL used by Azure Workload Identity federated credentials. |
| <a name="output_principal_id"></a> [principal\_id](#output\_principal\_id) | Principal ID of the AKS control-plane system-assigned managed identity. |
| <a name="output_private_fqdn"></a> [private\_fqdn](#output\_private\_fqdn) | Private API server FQDN when private-cluster mode is enabled. |
| <a name="output_user_node_pool_ids"></a> [user\_node\_pool\_ids](#output\_user\_node\_pool\_ids) | User node pool resource IDs keyed by pool name. |
<!-- END_TF_DOCS -->
