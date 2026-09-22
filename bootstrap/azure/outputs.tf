output "resource_group_name" {
  value       = azurerm_resource_group.state.name
  description = "State resource group name."
}

output "storage_account_name" {
  value       = azurerm_storage_account.state.name
  description = "State storage account name."
}

output "container_name" {
  value       = azurerm_storage_container.state.name
  description = "State container name."
}
