# Mocked computed IDs must be valid Azure resource IDs because the provider
# parses IDs passed between resources during planning.
mock_provider "azurerm" {
  mock_resource "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock"
    }
  }

  mock_resource "azurerm_virtual_network" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-mock"
    }
  }

  mock_resource "azurerm_subnet" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-mock/subnets/snet-mock"
    }
  }

  mock_resource "azurerm_network_security_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/networkSecurityGroups/nsg-mock"
    }
  }

  mock_resource "azurerm_log_analytics_workspace" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.OperationalInsights/workspaces/log-mock"
    }
  }

  mock_resource "azurerm_kubernetes_cluster" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.ContainerService/managedClusters/aks-mock"
    }
  }

  mock_resource "azurerm_storage_account" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Storage/storageAccounts/stmock"
    }
  }

  mock_resource "azurerm_key_vault" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.KeyVault/vaults/kv-mock"
    }
  }
}

variables {
  resource_group_name  = "rg-tfstate-platform-ci"
  location             = "centralindia"
  storage_account_name = "sttfstateplatform001"
  allowed_ip_rules     = ["203.0.113.10"]
  state_writer_principals = {
    github-plan = { principal_id = "22222222-2222-2222-2222-222222222222" }
  }
}

run "hardened_state_account" {
  command = plan

  assert {
    condition     = azurerm_storage_account.state.shared_access_key_enabled == false
    error_message = "State storage must not allow shared-key access."
  }

  assert {
    condition     = azurerm_storage_account.state.blob_properties[0].versioning_enabled == true
    error_message = "Blob versioning must be enabled for state recovery."
  }

  assert {
    condition     = azurerm_storage_account.state.network_rules[0].default_action == "Deny"
    error_message = "The state storage firewall must default to Deny."
  }

  assert {
    condition     = length(azurerm_management_lock.state) == 1
    error_message = "A delete lock must protect the state account by default."
  }

  assert {
    condition     = azurerm_role_assignment.state_writers["github-plan"].role_definition_name == "Storage Blob Data Contributor"
    error_message = "State writers must get data-plane RBAC, not keys."
  }
}

run "rejects_public_access_without_ip_rules" {
  command = plan

  variables {
    allowed_ip_rules = []
  }

  expect_failures = [var.allowed_ip_rules]
}

run "rejects_lrs_replication" {
  command = plan

  variables {
    replication_type = "LRS"
  }

  expect_failures = [var.replication_type]
}
