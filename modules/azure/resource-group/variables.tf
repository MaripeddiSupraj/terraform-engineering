variable "name" {
  description = "Name of the Azure resource group."
  type        = string

  validation {
    condition     = length(trimspace(var.name)) > 1
    error_message = "name must contain at least two non-space characters."
  }
}

variable "location" {
  description = "Azure region used by resources in the group."
  type        = string

  validation {
    condition     = length(trimspace(var.location)) > 1
    error_message = "location must not be empty."
  }
}

variable "tags" {
  description = "Tags applied to the resource group."
  type        = map(string)
  default     = {}
}
