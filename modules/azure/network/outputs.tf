output "id" {
  description = "Virtual network resource ID."
  value       = azurerm_virtual_network.this.id
}

output "name" {
  description = "Virtual network name."
  value       = azurerm_virtual_network.this.name
}

output "subnet_ids" {
  description = "Subnet resource IDs keyed by subnet name."
  value       = { for name, subnet in azurerm_subnet.this : name => subnet.id }
}
