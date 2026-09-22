output "id" {
  description = "Log Analytics workspace resource ID."
  value       = azurerm_log_analytics_workspace.this.id
}

output "workspace_id" {
  description = "Log Analytics workspace ID used by Azure integrations."
  value       = azurerm_log_analytics_workspace.this.workspace_id
}
