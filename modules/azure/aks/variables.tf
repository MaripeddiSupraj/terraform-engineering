variable "name" {
  description = "AKS cluster name."
  type        = string
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
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version. Set explicitly in production after checking versions supported in the target Azure region. Null lets Azure select its current default."
  type        = string
  default     = null
  nullable    = true
}

variable "sku_tier" {
  description = "AKS control-plane SKU tier."
  type        = string
  default     = "Standard"
}

variable "subnet_id" {
  description = "Subnet resource ID used by the system node pool."
  type        = string
}

variable "private_cluster_enabled" {
  description = "Whether the Kubernetes API server uses private-cluster mode."
  type        = bool
  default     = true
}

variable "admin_group_object_ids" {
  description = "Microsoft Entra group object IDs granted AKS admin access through Azure RBAC."
  type        = list(string)

  validation {
    condition     = length(var.admin_group_object_ids) > 0
    error_message = "At least one Microsoft Entra admin group object ID is required because local AKS accounts are disabled."
  }
}

variable "system_node_pool" {
  description = "System node-pool sizing and autoscaling configuration."
  type = object({
    name            = optional(string, "system")
    vm_size         = optional(string, "Standard_D4ds_v5")
    node_count      = optional(number, 3)
    min_count       = optional(number, 3)
    max_count       = optional(number, 6)
    os_disk_size_gb = optional(number, 128)
  })

  default = {}
}

variable "outbound_type" {
  description = "AKS outbound routing mode. Production network designs may override this for user-defined routing or managed NAT patterns."
  type        = string
  default     = "loadBalancer"
}

variable "log_analytics_workspace_id" {
  description = "Optional Log Analytics workspace resource ID used by the AKS monitoring agent."
  type        = string
  default     = null
  nullable    = true
}

variable "tags" {
  description = "Tags applied to the AKS cluster."
  type        = map(string)
  default     = {}
}
