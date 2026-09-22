mock_provider "azurerm" {}

run "private_secure_cluster" {
  command = plan

  variables {
    name                = "aks-platform-prod-ci"
    resource_group_name = "rg-platform-prod-ci"
    location            = "centralindia"
    dns_prefix          = "platform-prod-ci"
    subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-platform-prod-ci/providers/Microsoft.Network/virtualNetworks/vnet-platform-prod-ci/subnets/aks"
    admin_group_object_ids = [
      "11111111-1111-1111-1111-111111111111"
    ]
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this.private_cluster_enabled == true
    error_message = "Private cluster mode must be enabled by default."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this.workload_identity_enabled == true
    error_message = "Workload identity must remain enabled."
  }
}
