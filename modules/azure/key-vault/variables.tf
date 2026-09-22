variable "name" {
  description = "Globally unique Key Vault name."
  type        = string

  validation {
    condition     = length(var.name) >= 3 && length(var.name) <= 24
    error_message = "Key Vault names must contain between 3 and 24 characters."
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

variable "tags" {
  description = "Tags applied to the vault."
  type        = map(string)
  default     = {}
}
