variable "name" {
  description = "Globally unique Key Vault name."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{1,22}[a-zA-Z0-9]$", var.name)) && !strcontains(var.name, "--")
    error_message = "Key Vault names must be 3-24 alphanumeric/hyphen characters, start with a letter, end with a letter or digit, and not contain consecutive hyphens."
  }
}

variable "resource_group_name" {
  description = "Resource group containing the vault."
  type        = string
}

variable "location" {
  description = "Azure region for the vault."
  type        = string
}

variable "tenant_id" {
  description = "Microsoft Entra tenant ID used by the vault."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.tenant_id))
    error_message = "tenant_id must be a GUID."
  }
}

variable "sku_name" {
  description = "Key Vault SKU."
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "sku_name must be standard or premium."
  }
}

variable "purge_protection_enabled" {
  description = "Enable purge protection. Once enabled, Azure does not allow it to be disabled."
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "Soft-delete retention period."
  type        = number
  default     = 90

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "soft_delete_retention_days must be between 7 and 90."
  }
}

variable "public_network_access_enabled" {
  description = "Whether the Key Vault data plane is reachable through public networking. Keep false when private connectivity is configured."
  type        = bool
  default     = false
}

variable "network_bypass" {
  description = "Traffic allowed to bypass Key Vault network ACLs."
  type        = string
  default     = "AzureServices"

  validation {
    condition     = contains(["AzureServices", "None"], var.network_bypass)
    error_message = "network_bypass must be AzureServices or None."
  }
}

variable "allowed_ip_rules" {
  description = "Public IPv4 addresses or CIDR ranges explicitly allowed by the Key Vault firewall when public network access is enabled."
  type        = list(string)
  default     = []
}

variable "allowed_subnet_ids" {
  description = "Virtual network subnet resource IDs explicitly allowed by the Key Vault firewall."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to the vault."
  type        = map(string)
  default     = {}
}
