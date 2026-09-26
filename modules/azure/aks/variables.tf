variable "name" {
  description = "AKS cluster name."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9_-]{0,61}[a-zA-Z0-9]$", var.name))
    error_message = "name must be 2-63 characters of letters, numbers, hyphens or underscores, starting and ending with a letter or number."
  }
}

variable "resource_group_name" {
  description = "Resource group containing the AKS cluster."
  type        = string
}

variable "location" {
  description = "Azure region for the AKS cluster."
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix assigned to the AKS cluster."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{0,52}[a-zA-Z0-9]$", var.dns_prefix))
    error_message = "dns_prefix must be 2-54 alphanumeric/hyphen characters and start and end with a letter or number."
  }
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version. Set explicitly in production after checking versions supported in the target Azure region. Null lets Azure select its current default."
  type        = string
  default     = null
  nullable    = true
}

variable "sku_tier" {
  description = "AKS control-plane SKU tier. Standard includes the uptime SLA and is the production default."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Free", "Standard", "Premium"], var.sku_tier)
    error_message = "sku_tier must be Free, Standard, or Premium."
  }
}

variable "subnet_id" {
  description = "Subnet resource ID used by the system node pool and, unless overridden, by user node pools."
  type        = string
}

variable "availability_zones" {
  description = "Availability zones for node pools. Set to [] only in regions without zone support."
  type        = list(string)
  default     = ["1", "2", "3"]

  validation {
    condition     = alltrue([for z in var.availability_zones : contains(["1", "2", "3"], z)])
    error_message = "availability_zones entries must be \"1\", \"2\", or \"3\"."
  }
}

variable "private_cluster_enabled" {
  description = "Whether the Kubernetes API server uses private-cluster mode."
  type        = bool
  default     = true
}

variable "api_server_authorized_ip_ranges" {
  description = "CIDRs allowed to reach a public API server. Required when private_cluster_enabled is false; ignored otherwise."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.api_server_authorized_ip_ranges : can(cidrhost(cidr, 0)) && cidr != "0.0.0.0/0"])
    error_message = "api_server_authorized_ip_ranges must be valid CIDRs and must not include 0.0.0.0/0."
  }
}

variable "admin_group_object_ids" {
  description = "Microsoft Entra group object IDs granted AKS admin access through Azure RBAC."
  type        = list(string)

  validation {
    condition     = length(var.admin_group_object_ids) > 0
    error_message = "At least one Microsoft Entra admin group object ID is required because local AKS accounts are disabled."
  }

  validation {
    condition     = alltrue([for id in var.admin_group_object_ids : can(regex("^[0-9a-fA-F-]{36}$", id))])
    error_message = "admin_group_object_ids must be Microsoft Entra object IDs (GUIDs)."
  }
}

variable "system_node_pool" {
  description = "System node-pool sizing, autoscaling and isolation configuration."
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

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{0,11}$", var.system_node_pool.name)) && can(regex("^[a-z][a-z0-9]{0,11}$", var.system_node_pool.temporary_name_for_rotation))
    error_message = "system_node_pool.name and temporary_name_for_rotation must be 1-12 lowercase alphanumeric characters starting with a letter."
  }

  validation {
    condition     = var.system_node_pool.min_count >= 1
    error_message = "system_node_pool.min_count must be at least 1."
  }
}

variable "user_node_pools" {
  description = "User node pools keyed by pool name (1-12 lowercase alphanumeric). Each pool autoscales; set spot = true for interruptible capacity."
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
  default = {}

  validation {
    condition     = alltrue([for name in keys(var.user_node_pools) : can(regex("^[a-z][a-z0-9]{0,11}$", name))])
    error_message = "user_node_pools keys must be 1-12 lowercase alphanumeric characters starting with a letter."
  }
}

variable "automatic_upgrade_channel" {
  description = "Cluster auto-upgrade channel. patch keeps the minor version pinned while applying supported patches. Null disables auto-upgrade."
  type        = string
  default     = "patch"
  nullable    = true

  validation {
    condition     = var.automatic_upgrade_channel == null || contains(["patch", "stable", "rapid", "node-image"], coalesce(var.automatic_upgrade_channel, "patch"))
    error_message = "automatic_upgrade_channel must be patch, stable, rapid, node-image, or null."
  }
}

variable "node_os_upgrade_channel" {
  description = "Node OS image upgrade channel."
  type        = string
  default     = "NodeImage"

  validation {
    condition     = contains(["Unmanaged", "SecurityPatch", "NodeImage", "None"], var.node_os_upgrade_channel)
    error_message = "node_os_upgrade_channel must be Unmanaged, SecurityPatch, NodeImage, or None."
  }
}

variable "maintenance_window" {
  description = "Weekly planned-maintenance window applied to both cluster auto-upgrades and node OS upgrades. Null lets AKS upgrade at any time."
  type = object({
    day_of_week    = optional(string, "Sunday")
    start_time     = optional(string, "02:00")
    utc_offset     = optional(string, "+00:00")
    duration_hours = optional(number, 4)
  })
  default  = {}
  nullable = true

  validation {
    condition = var.maintenance_window == null || (
      contains(["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"], try(var.maintenance_window.day_of_week, "")) &&
      can(regex("^([01][0-9]|2[0-3]):[0-5][0-9]$", try(var.maintenance_window.start_time, ""))) &&
      try(var.maintenance_window.duration_hours >= 4 && var.maintenance_window.duration_hours <= 24, false)
    )
    error_message = "maintenance_window needs a valid day_of_week, HH:mm start_time, and duration_hours between 4 and 24."
  }
}

variable "network_plugin_mode" {
  description = "Azure CNI mode. overlay (recommended) keeps pod IPs out of the VNet; null uses flat Azure CNI where pods consume subnet IPs."
  type        = string
  default     = "overlay"
  nullable    = true

  validation {
    condition     = var.network_plugin_mode == null || var.network_plugin_mode == "overlay"
    error_message = "network_plugin_mode must be overlay or null."
  }
}

variable "network_data_plane" {
  description = "AKS network data plane. cilium also selects Cilium network policy; azure selects Azure network policy."
  type        = string
  default     = "cilium"

  validation {
    condition     = contains(["azure", "cilium"], var.network_data_plane)
    error_message = "network_data_plane must be azure or cilium."
  }
}

variable "pod_cidr" {
  description = "Pod CIDR used in overlay mode. Must not overlap the VNet, peered networks, or service_cidr."
  type        = string
  default     = "192.168.0.0/16"

  validation {
    condition     = can(cidrhost(var.pod_cidr, 0))
    error_message = "pod_cidr must be a valid CIDR."
  }
}

variable "service_cidr" {
  description = "Kubernetes service CIDR. Null uses the AKS default. Must not overlap the VNet or pod_cidr."
  type        = string
  default     = null
  nullable    = true
}

variable "dns_service_ip" {
  description = "kube-dns service IP inside service_cidr. Set together with service_cidr."
  type        = string
  default     = null
  nullable    = true
}

variable "outbound_type" {
  description = "AKS outbound routing mode. Production hub/spoke designs typically use userDefinedRouting through a firewall or a NAT gateway."
  type        = string
  default     = "loadBalancer"

  validation {
    condition     = contains(["loadBalancer", "userDefinedRouting", "managedNATGateway", "userAssignedNATGateway", "none"], var.outbound_type)
    error_message = "outbound_type must be loadBalancer, userDefinedRouting, managedNATGateway, userAssignedNATGateway, or none."
  }
}

variable "log_analytics_workspace_id" {
  description = "Optional Log Analytics workspace resource ID used by the AKS monitoring agent."
  type        = string
  default     = null
  nullable    = true
}

variable "tags" {
  description = "Tags applied to the AKS cluster and its node pools."
  type        = map(string)
  default     = {}
}
