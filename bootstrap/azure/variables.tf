variable "resource_group_name" {
  description = "Resource group created for Terraform remote-state infrastructure."
  type        = string
}

variable "location" {
  description = "Azure region for state infrastructure."
  type        = string
}

variable "storage_account_name" {
  description = "Globally unique Azure Storage account name used for Terraform state."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "storage_account_name must contain 3-24 lowercase letters or numbers."
  }
}

variable "container_name" {
  description = "Blob container used for Terraform state."
  type        = string
  default     = "tfstate"
}

variable "replication_type" {
  description = "Storage replication. ZRS survives a zone outage; GZRS also survives a regional outage."
  type        = string
  default     = "ZRS"

  validation {
    condition     = contains(["ZRS", "GZRS", "RAGZRS"], var.replication_type)
    error_message = "replication_type must be ZRS, GZRS, or RAGZRS for state storage."
  }
}

variable "soft_delete_retention_days" {
  description = "Blob and container soft-delete retention, in days."
  type        = number
  default     = 30

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 365
    error_message = "soft_delete_retention_days must be between 7 and 365."
  }
}

variable "public_network_access_enabled" {
  description = "Whether the state storage account is reachable from public networking. Requires allowed_ip_rules. Disable once private CI connectivity exists."
  type        = bool
  default     = true
}

variable "allowed_ip_rules" {
  description = "Public IPv4 addresses or CIDR ranges allowed through the state storage firewall. Required when public network access is enabled."
  type        = list(string)
  default     = []

  validation {
    condition     = !var.public_network_access_enabled || length(var.allowed_ip_rules) > 0
    error_message = "public_network_access_enabled = true with an empty allowed_ip_rules list makes state unreachable (the firewall defaults to Deny). Add your runner's egress IP or disable public access."
  }

  validation {
    condition     = !contains(var.allowed_ip_rules, "0.0.0.0/0")
    error_message = "allowed_ip_rules must not contain 0.0.0.0/0."
  }
}

variable "delete_lock_enabled" {
  description = "Apply a CanNotDelete management lock to the state storage account."
  type        = bool
  default     = true
}

variable "state_writer_principals" {
  description = "Principals granted Storage Blob Data Contributor on the state account, keyed by a stable label (for example github-prod-plan)."
  type = map(object({
    principal_id   = string
    principal_type = optional(string, "ServicePrincipal")
  }))
  default = {}

  validation {
    condition     = alltrue([for p in values(var.state_writer_principals) : contains(["User", "Group", "ServicePrincipal"], p.principal_type)])
    error_message = "principal_type must be User, Group, or ServicePrincipal."
  }
}

variable "tags" {
  description = "Tags applied to state infrastructure."
  type        = map(string)
  default     = {}
}
