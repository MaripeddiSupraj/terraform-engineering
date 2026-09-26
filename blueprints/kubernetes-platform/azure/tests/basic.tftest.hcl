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
  project             = "payments"
  environment         = "prod"
  location            = "centralindia"
  location_short      = "ci"
  address_space       = ["10.20.0.0/16"]
  aks_subnet_prefixes = ["10.20.0.0/22"]
  aks_admin_group_object_ids = [
    "11111111-1111-1111-1111-111111111111"
  ]
  tags = {
    owner = "platform-engineering"
  }
}

run "platform_composition" {
  command = plan

  assert {
    condition     = module.aks.name == "aks-payments-prod-ci"
    error_message = "Blueprint naming contract changed unexpectedly."
  }

  assert {
    condition     = contains(keys(module.aks.user_node_pool_ids), "apps")
    error_message = "The blueprint must ship a default user node pool for application workloads."
  }

  assert {
    condition     = contains(keys(module.network.network_security_group_ids), "aks")
    error_message = "The AKS subnet must have an NSG."
  }
}

run "required_tags_are_applied" {
  command = plan

  assert {
    condition = alltrue([
      for key in ["environment", "managed-by", "project", "owner"] :
      contains(keys(module.resource_group.tags), key)
    ])
    error_message = "Framework tags (environment, managed-by, project) and caller tags must reach every resource."
  }
}

run "rejects_invalid_environment" {
  command = plan

  variables {
    environment = "production"
  }

  expect_failures = [var.environment]
}
