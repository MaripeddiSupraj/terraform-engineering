resource "azurerm_kubernetes_cluster" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.sku_tier

  private_cluster_enabled         = var.private_cluster_enabled
  role_based_access_control_enabled = true
  local_account_disabled          = true
  oidc_issuer_enabled             = true
  workload_identity_enabled       = true
  azure_policy_enabled            = true

  default_node_pool {
    name                 = var.system_node_pool.name
    vm_size              = var.system_node_pool.vm_size
    vnet_subnet_id       = var.subnet_id
    auto_scaling_enabled = true
    min_count            = var.system_node_pool.min_count
    max_count            = var.system_node_pool.max_count
    node_count           = var.system_node_pool.node_count
    os_disk_size_gb      = var.system_node_pool.os_disk_size_gb
    type                 = "VirtualMachineScaleSets"
  }

  identity {
    type = "SystemAssigned"
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled       = true
    admin_group_object_ids   = var.admin_group_object_ids
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    outbound_type     = var.outbound_type
  }

  dynamic "oms_agent" {
    for_each = var.log_analytics_workspace_id == null ? [] : [1]

    content {
      log_analytics_workspace_id      = var.log_analytics_workspace_id
      msi_auth_for_monitoring_enabled = true
    }
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.system_node_pool.min_count <= var.system_node_pool.node_count && var.system_node_pool.node_count <= var.system_node_pool.max_count
      error_message = "system_node_pool.node_count must be between min_count and max_count."
    }
  }
}
