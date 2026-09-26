output "id" {
  description = "Resource group resource ID."
  value       = azurerm_resource_group.this.id
}

output "name" {
  description = "Resource group name."
  value       = azurerm_resource_group.this.name
}

output "location" {
  description = "Resource group Azure region."
  value       = azurerm_resource_group.this.location
}

output "tags" {
  description = "Tags applied to the resource group, for callers that verify tag propagation."
  value       = azurerm_resource_group.this.tags
}
