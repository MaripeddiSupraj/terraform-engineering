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

variable "dns_servers" {
  description = "Custom DNS servers for the VNet. Empty uses Azure-provided DNS."
  type        = list(string)
  default     = []
}

variable "subnets" {
  description = <<-EOT
    Subnets keyed by stable subnet name. Each subnet gets its own NSG by default
    (network_security_group.enabled = true). Rules are keyed by rule name; an
    empty rule map keeps Azure's default rules, which deny inbound internet traffic.
  EOT
  type = map(object({
    address_prefixes                  = list(string)
    service_endpoints                 = optional(set(string), [])
    default_outbound_access_enabled   = optional(bool, false)
    private_endpoint_network_policies = optional(string, "Enabled")
    delegation = optional(object({
      name    = string
      service = string
      actions = optional(list(string), [])
    }))
    network_security_group = optional(object({
      enabled = optional(bool, true)
      rules = optional(map(object({
        priority                     = number
        direction                    = string
        access                       = string
        protocol                     = string
        destination_port_ranges      = list(string)
        source_address_prefixes      = list(string)
        destination_address_prefixes = list(string)
        description                  = optional(string)
      })), {})
    }), {})
  }))

  validation {
    condition = alltrue(flatten([
      for subnet in values(var.subnets) : [
        for cidr in subnet.address_prefixes : can(cidrhost(cidr, 0))
      ]
    ]))
    error_message = "Every subnet address prefix must be a valid CIDR block."
  }

  validation {
    condition = alltrue([
      for subnet in values(var.subnets) : contains(["Disabled", "Enabled", "NetworkSecurityGroupEnabled", "RouteTableEnabled"], subnet.private_endpoint_network_policies)
    ])
    error_message = "private_endpoint_network_policies must be Disabled, Enabled, NetworkSecurityGroupEnabled, or RouteTableEnabled."
  }

  # Inbound allow rules from anywhere are the most common accidental exposure.
  # Require them to be spelled out as a specific prefix instead.
  validation {
    condition = alltrue(flatten([
      for subnet in values(var.subnets) : [
        for rule in values(subnet.network_security_group.rules) :
        !(rule.direction == "Inbound" && rule.access == "Allow" && length(setintersection(toset(rule.source_address_prefixes), toset(["*", "0.0.0.0/0", "Internet", "Any"]))) > 0)
      ]
    ]))
    error_message = "Inbound Allow rules must not use *, 0.0.0.0/0, Internet, or Any as a source. Front public traffic with a load balancer, Application Gateway, or Front Door instead."
  }

  validation {
    condition = alltrue(flatten([
      for subnet in values(var.subnets) : [
        for rule in values(subnet.network_security_group.rules) :
        contains(["Inbound", "Outbound"], rule.direction) && contains(["Allow", "Deny"], rule.access) && rule.priority >= 100 && rule.priority <= 4096
      ]
    ]))
    error_message = "NSG rules need direction Inbound/Outbound, access Allow/Deny, and priority 100-4096."
  }
}

variable "tags" {
  description = "Tags applied to the virtual network and network security groups."
  type        = map(string)
  default     = {}
}
