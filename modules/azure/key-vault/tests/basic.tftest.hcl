mock_provider "azurerm" {}

run "secure_defaults" {
  command = plan

  variables {
    name                = "kvplatformprodci001"
    resource_group_name = "rg-platform-prod-ci"
    location            = "centralindia"
    tenant_id           = "00000000-0000-0000-0000-000000000000"
  }

  assert {
    condition     = azurerm_key_vault.this.rbac_authorization_enabled == true
    error_message = "Key Vault must use RBAC authorization."
  }

  assert {
    condition     = azurerm_key_vault.this.public_network_access_enabled == false
    error_message = "Public network access must be disabled by default."
  }
}
