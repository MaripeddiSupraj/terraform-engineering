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

output "backend_config" {
  description = "Values for an azurerm backend block. Add a unique key per root module and environment. Contains no credentials."
  value = {
    resource_group_name  = azurerm_resource_group.state.name
    storage_account_name = azurerm_storage_account.state.name
    container_name       = azurerm_storage_container.state.name
    use_azuread_auth     = true
  }
}
