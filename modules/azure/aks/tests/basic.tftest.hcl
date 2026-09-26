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
  name                = "aks-platform-prod-ci"
  resource_group_name = "rg-platform-prod-ci"
  location            = "centralindia"
  dns_prefix          = "platform-prod-ci"
  subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-platform-prod-ci/providers/Microsoft.Network/virtualNetworks/vnet-platform-prod-ci/subnets/aks"
  admin_group_object_ids = [
    "11111111-1111-1111-1111-111111111111"
  ]
  user_node_pools = {
    apps = {}
  }
}

run "secure_defaults" {
  command = plan

  assert {
    condition     = azurerm_kubernetes_cluster.this.private_cluster_enabled == true
    error_message = "Private cluster mode must be enabled by default."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this.workload_identity_enabled == true && azurerm_kubernetes_cluster.this.oidc_issuer_enabled == true
    error_message = "Workload identity and the OIDC issuer must remain enabled."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this.local_account_disabled == true
    error_message = "Local accounts must stay disabled."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this.default_node_pool[0].only_critical_addons_enabled == true
    error_message = "The system pool must be reserved for critical add-ons by default."
  }

  assert {
    condition     = length(azurerm_kubernetes_cluster.this.default_node_pool[0].zones) == 3
    error_message = "Node pools must span three availability zones by default."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this.automatic_upgrade_channel == "patch"
    error_message = "Automatic patch upgrades must be enabled by default."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this.network_profile[0].network_plugin_mode == "overlay"
    error_message = "Azure CNI Overlay must be the default network mode."
  }

  assert {
    condition     = azurerm_kubernetes_cluster_node_pool.user["apps"].mode == "User"
    error_message = "User node pools must be created in User mode."
  }
}

run "spot_pool_gets_spot_taint" {
  command = plan

  variables {
    user_node_pools = {
      batch = {
        spot      = true
        min_count = 0
      }
    }
  }

  assert {
    condition     = azurerm_kubernetes_cluster_node_pool.user["batch"].priority == "Spot"
    error_message = "spot = true must create a Spot priority pool."
  }

  assert {
    condition     = contains(azurerm_kubernetes_cluster_node_pool.user["batch"].node_taints, "kubernetes.azure.com/scalesetpriority=spot:NoSchedule")
    error_message = "Spot pools must carry the AKS spot taint to avoid a perpetual diff."
  }
}

run "rejects_empty_admin_groups" {
  command = plan

  variables {
    admin_group_object_ids = []
  }

  expect_failures = [var.admin_group_object_ids]
}

run "rejects_public_api_without_authorized_ranges" {
  command = plan

  variables {
    private_cluster_enabled = false
  }

  expect_failures = [azurerm_kubernetes_cluster.this]
}

run "rejects_open_authorized_range" {
  command = plan

  variables {
    private_cluster_enabled         = false
    api_server_authorized_ip_ranges = ["0.0.0.0/0"]
  }

  expect_failures = [var.api_server_authorized_ip_ranges]
}

run "rejects_node_count_outside_bounds" {
  command = plan

  variables {
    system_node_pool = {
      node_count = 10
      min_count  = 3
      max_count  = 6
    }
  }

  expect_failures = [azurerm_kubernetes_cluster.this]
}

run "rejects_invalid_sku_tier" {
  command = plan

  variables {
    sku_tier = "Gold"
  }

  expect_failures = [var.sku_tier]
}
