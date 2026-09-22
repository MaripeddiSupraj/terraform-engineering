variable "name" {
  description = "Virtual network name."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group containing the virtual network."
  type        = string
}

variable "location" {
  description = "Azure region for the virtual network."
  type        = string
}

variable "address_space" {
  description = "CIDR ranges assigned to the virtual network."
  type        = list(string)

  validation {
    condition     = length(var.address_space) > 0 && alltrue([for cidr in var.address_space : can(cidrhost(cidr, 0))])
    error_message = "address_space must contain at least one valid CIDR block."
  }
}

variable "subnets" {
  description = "Subnets keyed by stable subnet name."
  type = map(object({
    address_prefixes  = list(string)
    service_endpoints = optional(set(string), [])
  }))

  validation {
    condition = alltrue(flatten([
      for subnet in values(var.subnets) : [
        for cidr in subnet.address_prefixes : can(cidrhost(cidr, 0))
      ]
    ]))
    error_message = "Every subnet address prefix must be a valid CIDR block."
  }
}

variable "tags" {
  description = "Tags applied to the virtual network."
  type        = map(string)
  default     = {}
}
