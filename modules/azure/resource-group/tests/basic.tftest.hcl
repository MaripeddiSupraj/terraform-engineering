mock_provider "azurerm" {}

run "valid_resource_group" {
  command = plan

  variables {
    name     = "rg-platform-prod-ci"
    location = "centralindia"
    tags = {
      environment = "prod"
    }
  }

  assert {
    condition     = azurerm_resource_group.this.name == "rg-platform-prod-ci"
    error_message = "The resource group name was not passed through correctly."
  }
}
