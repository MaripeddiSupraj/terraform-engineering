variable "project" {
  description = "Short project identifier used in resource names and tags."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{2,18}$", var.project))
    error_message = "project must be 2-18 lowercase alphanumeric/hyphen characters."
  }
}

variable "environment" {
  description = "Deployment environment."
  type        = string

  validation {
    condition     = contains(["dev", "test", "stage", "prod"], var.environment)
    error_message = "environment must be dev, test, stage, or prod."
  }
}

variable "location" {
  description = "Azure region name."
  type        = string
}

variable "location_short" {
  description = "Short stable region token used only in resource names, for example ci for Central India."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{2,6}$", var.location_short))
    error_message = "location_short must be 2-6 lowercase alphanumeric characters."
  }
}

variable "address_space" {
  description = "Virtual network CIDR ranges."
  type        = list(string)
}

variable "aks_subnet_prefixes" {
  description = "CIDR ranges assigned to the AKS node subnet."
  type        = list(string)
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version supported in the target region. Null lets Azure select the current default."
  type        = string
  default     = null
  nullable    = true
}

variable "private_cluster_enabled" {
  description = "Deploy AKS with a private API endpoint."
  type        = bool
  default     = true
}

variable "aks_admin_group_object_ids" {
  description = "Microsoft Entra group object IDs with AKS admin privileges."
  type        = list(string)

  validation {
    condition     = length(var.aks_admin_group_object_ids) > 0
    error_message = "At least one AKS admin group object ID is required."
  }
}

variable "api_server_authorized_ip_ranges" {
  description = "CIDRs allowed to reach the API server. Required only when private_cluster_enabled is false."
  type        = list(string)
  default     = []
}

variable "availability_zones" {
  description = "Availability zones for node pools. Use [] only in regions without zone support."
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "system_node_pool" {
  description = "AKS system node pool. Reserved for critical add-ons by default; applications run on user_node_pools."
  type = object({
    name                         = optional(string, "system")
    temporary_name_for_rotation  = optional(string, "systemtmp")
    vm_size                      = optional(string, "Standard_D4ds_v5")
    node_count                   = optional(number, 3)
    min_count                    = optional(number, 3)
    max_count                    = optional(number, 6)
    max_pods                     = optional(number, 110)
    os_disk_size_gb              = optional(number, 128)
    os_sku                       = optional(string, "AzureLinux")
    only_critical_addons_enabled = optional(bool, true)
    max_surge                    = optional(string, "33%")
  })
  default = {}
}

variable "user_node_pools" {
  description = "AKS user node pools keyed by pool name (1-12 lowercase alphanumeric). Application workloads schedule here."
  type = map(object({
    vm_size                     = optional(string, "Standard_D4ds_v5")
    temporary_name_for_rotation = optional(string)
    node_count                  = optional(number, 2)
    min_count                   = optional(number, 2)
    max_count                   = optional(number, 10)
    max_pods                    = optional(number, 110)
    os_disk_size_gb             = optional(number, 128)
    os_sku                      = optional(string, "AzureLinux")
    subnet_id                   = optional(string)
    zones                       = optional(list(string))
    node_labels                 = optional(map(string), {})
    node_taints                 = optional(list(string), [])
    spot                        = optional(bool, false)
    max_surge                   = optional(string, "33%")
  }))
  default = {
    apps = {}
  }
}

variable "maintenance_window" {
  description = "Weekly maintenance window for cluster and node OS upgrades. Null allows upgrades at any time."
  type = object({
    day_of_week    = optional(string, "Sunday")
    start_time     = optional(string, "02:00")
    utc_offset     = optional(string, "+00:00")
    duration_hours = optional(number, 4)
  })
  default  = {}
  nullable = true
}

variable "log_retention_days" {
  description = "Log Analytics retention period."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Additional tags merged with required framework tags."
  type        = map(string)
  default     = {}
}
