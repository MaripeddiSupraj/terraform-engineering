resource "azurerm_log_analytics_workspace" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  retention_in_days   = var.retention_in_days

  # Entra ID only: shared workspace keys are long-lived credentials that
  # bypass RBAC and cannot be scoped or audited per caller.
  local_authentication_enabled = var.local_authentication_enabled
  tags                         = var.tags
}
