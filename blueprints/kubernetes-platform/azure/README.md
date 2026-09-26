# Azure Kubernetes Platform Blueprint

Reference composition showing how agents and humans build infrastructure with
this framework: **compose reviewed modules instead of generating a platform
from scratch.**

It creates:

- a resource group;
- a virtual network with an AKS subnet and its NSG;
- a Log Analytics workspace (Entra ID auth only);
- a private AKS cluster (Overlay + Cilium, zones 1-3, Entra RBAC, workload
  identity, auto-upgrades in a maintenance window) with an `apps` user pool.

## Deploy

```bash
# 1. Remote state (once per subscription): see bootstrap/azure
cp backend.tf.example backend.tf                       # fill in from bootstrap output

# 2. Inputs: either edit tfvars by hand ...
cp terraform.tfvars.example terraform.tfvars
# ... or render them from a validated request
python3 ../../../scripts/request-to-tfvars.py ../../../examples/requests/azure-aks.yaml -o terraform.tfvars.json

# 3. Validate, plan with policy gate, review, apply the saved plan
terraform init
terraform validate && terraform test
../../../scripts/capture-plan.sh .
terraform apply .evidence/<timestamp>/tfplan
```

## Production considerations not covered yet

Private DNS / hub-spoke connectivity for the private API server, egress through
a firewall (`outbound_type = "userDefinedRouting"`), private endpoints, ingress,
backup, Defender, and managed Prometheus. Add them as reviewed modules, not as
ad-hoc code inside this blueprint.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | = 1.16.3 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | = 5.4.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_aks"></a> [aks](#module\_aks) | ../../../modules/azure/aks | n/a |
| <a name="module_monitoring"></a> [monitoring](#module\_monitoring) | ../../../modules/azure/log-analytics | n/a |
| <a name="module_network"></a> [network](#module\_network) | ../../../modules/azure/network | n/a |
| <a name="module_resource_group"></a> [resource\_group](#module\_resource\_group) | ../../../modules/azure/resource-group | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_address_space"></a> [address\_space](#input\_address\_space) | Virtual network CIDR ranges. | `list(string)` | n/a | yes |
| <a name="input_aks_admin_group_object_ids"></a> [aks\_admin\_group\_object\_ids](#input\_aks\_admin\_group\_object\_ids) | Microsoft Entra group object IDs with AKS admin privileges. | `list(string)` | n/a | yes |
| <a name="input_aks_subnet_prefixes"></a> [aks\_subnet\_prefixes](#input\_aks\_subnet\_prefixes) | CIDR ranges assigned to the AKS node subnet. | `list(string)` | n/a | yes |
| <a name="input_api_server_authorized_ip_ranges"></a> [api\_server\_authorized\_ip\_ranges](#input\_api\_server\_authorized\_ip\_ranges) | CIDRs allowed to reach the API server. Required only when private\_cluster\_enabled is false. | `list(string)` | `[]` | no |
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | Availability zones for node pools. Use [] only in regions without zone support. | `list(string)` | <pre>[<br/>  "1",<br/>  "2",<br/>  "3"<br/>]</pre> | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Deployment environment. | `string` | n/a | yes |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | AKS Kubernetes version supported in the target region. Null lets Azure select the current default. | `string` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region name. | `string` | n/a | yes |
| <a name="input_location_short"></a> [location\_short](#input\_location\_short) | Short stable region token used only in resource names, for example ci for Central India. | `string` | n/a | yes |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | Log Analytics retention period. | `number` | `30` | no |
| <a name="input_maintenance_window"></a> [maintenance\_window](#input\_maintenance\_window) | Weekly maintenance window for cluster and node OS upgrades. Null allows upgrades at any time. | <pre>object({<br/>    day_of_week    = optional(string, "Sunday")<br/>    start_time     = optional(string, "02:00")<br/>    utc_offset     = optional(string, "+00:00")<br/>    duration_hours = optional(number, 4)<br/>  })</pre> | `{}` | no |
| <a name="input_private_cluster_enabled"></a> [private\_cluster\_enabled](#input\_private\_cluster\_enabled) | Deploy AKS with a private API endpoint. | `bool` | `true` | no |
| <a name="input_project"></a> [project](#input\_project) | Short project identifier used in resource names and tags. | `string` | n/a | yes |
| <a name="input_system_node_pool"></a> [system\_node\_pool](#input\_system\_node\_pool) | AKS system node pool. Reserved for critical add-ons by default; applications run on user\_node\_pools. | <pre>object({<br/>    name                         = optional(string, "system")<br/>    temporary_name_for_rotation  = optional(string, "systemtmp")<br/>    vm_size                      = optional(string, "Standard_D4ds_v5")<br/>    node_count                   = optional(number, 3)<br/>    min_count                    = optional(number, 3)<br/>    max_count                    = optional(number, 6)<br/>    max_pods                     = optional(number, 110)<br/>    os_disk_size_gb              = optional(number, 128)<br/>    os_sku                       = optional(string, "AzureLinux")<br/>    only_critical_addons_enabled = optional(bool, true)<br/>    max_surge                    = optional(string, "33%")<br/>  })</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags merged with required framework tags. | `map(string)` | `{}` | no |
| <a name="input_user_node_pools"></a> [user\_node\_pools](#input\_user\_node\_pools) | AKS user node pools keyed by pool name (1-12 lowercase alphanumeric). Application workloads schedule here. | <pre>map(object({<br/>    vm_size                     = optional(string, "Standard_D4ds_v5")<br/>    temporary_name_for_rotation = optional(string)<br/>    node_count                  = optional(number, 2)<br/>    min_count                   = optional(number, 2)<br/>    max_count                   = optional(number, 10)<br/>    max_pods                    = optional(number, 110)<br/>    os_disk_size_gb             = optional(number, 128)<br/>    os_sku                      = optional(string, "AzureLinux")<br/>    subnet_id                   = optional(string)<br/>    zones                       = optional(list(string))<br/>    node_labels                 = optional(map(string), {})<br/>    node_taints                 = optional(list(string), [])<br/>    spot                        = optional(bool, false)<br/>    max_surge                   = optional(string, "33%")<br/>  }))</pre> | <pre>{<br/>  "apps": {}<br/>}</pre> | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_aks_cluster_id"></a> [aks\_cluster\_id](#output\_aks\_cluster\_id) | AKS cluster resource ID. |
| <a name="output_aks_cluster_name"></a> [aks\_cluster\_name](#output\_aks\_cluster\_name) | AKS cluster name. |
| <a name="output_aks_oidc_issuer_url"></a> [aks\_oidc\_issuer\_url](#output\_aks\_oidc\_issuer\_url) | AKS OIDC issuer URL for workload identity federation. |
| <a name="output_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#output\_log\_analytics\_workspace\_id) | Log Analytics workspace resource ID. |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Platform resource group name. |
| <a name="output_virtual_network_id"></a> [virtual\_network\_id](#output\_virtual\_network\_id) | Platform virtual network resource ID. |
<!-- END_TF_DOCS -->
