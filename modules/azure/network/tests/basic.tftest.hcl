mock_provider "azurerm" {}

run "network_with_aks_subnet" {
  command = plan

  variables {
    name                = "vnet-platform-prod-ci"
    resource_group_name = "rg-platform-prod-ci"
    location            = "centralindia"
    address_space       = ["10.20.0.0/16"]
    subnets = {
      aks = {
        address_prefixes = ["10.20.0.0/20"]
      }
    }
  }

  assert {
    condition     = length(azurerm_subnet.this) == 1
    error_message = "Expected exactly one subnet."
  }
}
