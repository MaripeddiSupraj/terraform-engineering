mock_provider "azurerm" {}

run "workspace_defaults" {
  command = plan

  variables {
    name                = "log-platform-prod-ci"
    resource_group_name = "rg-platform-prod-ci"
    location            = "centralindia"
  }

  assert {
    condition     = azurerm_log_analytics_workspace.this.retention_in_days == 30
    error_message = "Expected the module retention default to remain 30 days."
  }
}
