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

variable "public_network_access_enabled" {
  description = "Whether the state storage account is reachable from public networking. Disable after private CI connectivity is available."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to state infrastructure."
  type        = map(string)
  default     = {}
}
