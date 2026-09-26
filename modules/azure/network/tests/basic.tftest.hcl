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
  name                = "vnet-platform-prod-ci"
  resource_group_name = "rg-platform-prod-ci"
  location            = "centralindia"
  address_space       = ["10.20.0.0/16"]
  subnets = {
    aks = {
      address_prefixes = ["10.20.0.0/22"]
    }
    endpoints = {
      address_prefixes       = ["10.20.4.0/24"]
      network_security_group = { enabled = false }
    }
  }
}

run "secure_subnet_defaults" {
  command = plan

  assert {
    condition     = length(azurerm_subnet.this) == 2
    error_message = "Expected two subnets."
  }

  assert {
    condition     = azurerm_subnet.this["aks"].default_outbound_access_enabled == false
    error_message = "Implicit default outbound internet access must be disabled by default."
  }

  assert {
    condition     = length(azurerm_network_security_group.this) == 1 && contains(keys(azurerm_subnet_network_security_group_association.this), "aks")
    error_message = "Subnets must get an associated NSG unless explicitly opted out."
  }
}

run "rejects_internet_inbound_allow" {
  command = plan

  variables {
    subnets = {
      web = {
        address_prefixes = ["10.20.8.0/24"]
        network_security_group = {
          rules = {
            allow-https = {
              priority                     = 100
              direction                    = "Inbound"
              access                       = "Allow"
              protocol                     = "Tcp"
              destination_port_ranges      = ["443"]
              source_address_prefixes      = ["0.0.0.0/0"]
              destination_address_prefixes = ["10.20.8.0/24"]
            }
          }
        }
      }
    }
  }

  expect_failures = [var.subnets]
}

run "rejects_invalid_cidr" {
  command = plan

  variables {
    address_space = ["10.20.0.0/33"]
  }

  expect_failures = [var.address_space]
}
