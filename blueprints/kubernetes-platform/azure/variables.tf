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

variable "system_node_pool" {
  description = "AKS system node pool configuration."
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
