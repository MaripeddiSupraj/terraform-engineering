resource "azurerm_kubernetes_cluster" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.sku_tier

  private_cluster_enabled           = var.private_cluster_enabled
  role_based_access_control_enabled = true
  local_account_disabled            = true
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true
  azure_policy_enabled              = true

  automatic_upgrade_channel = var.automatic_upgrade_channel
  node_os_upgrade_channel   = var.node_os_upgrade_channel

  default_node_pool {
    name                         = var.system_node_pool.name
    temporary_name_for_rotation  = var.system_node_pool.temporary_name_for_rotation
    vm_size                      = var.system_node_pool.vm_size
    vnet_subnet_id               = var.subnet_id
    zones                        = var.availability_zones
    auto_scaling_enabled         = true
    min_count                    = var.system_node_pool.min_count
    max_count                    = var.system_node_pool.max_count
    node_count                   = var.system_node_pool.node_count
    max_pods                     = var.system_node_pool.max_pods
    os_disk_size_gb              = var.system_node_pool.os_disk_size_gb
    os_sku                       = var.system_node_pool.os_sku
    only_critical_addons_enabled = var.system_node_pool.only_critical_addons_enabled
    type                         = "VirtualMachineScaleSets"
    tags                         = var.tags

    upgrade_settings {
      max_surge = var.system_node_pool.max_surge
    }
  }

  # AzureRM 5.x requires this block. Manual mode keeps node-pool lifecycle
  # explicit in Terraform instead of enabling AKS node auto-provisioning.
  node_provisioning_profile {
    mode = "Manual"
  }

  identity {
    type = "SystemAssigned"
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled     = true
    admin_group_object_ids = var.admin_group_object_ids
  }

  # Only rendered for public clusters: a public API server must always be
  # restricted to explicit CIDRs (enforced by the precondition below).
  dynamic "api_server_access_profile" {
    for_each = var.private_cluster_enabled ? [] : [1]

    content {
      authorized_ip_ranges = var.api_server_authorized_ip_ranges
    }
  }

  # Azure CNI Overlay keeps pod IPs out of the VNet address space, so node
  # subnets can stay small and hub/spoke addressing does not need resizing as
  # pod density grows. Cilium provides the data plane and network policy.
  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = var.network_plugin_mode
    network_data_plane  = var.network_data_plane
    network_policy      = var.network_data_plane == "cilium" ? "cilium" : "azure"
    load_balancer_sku   = "standard"
    outbound_type       = var.outbound_type
    pod_cidr            = var.network_plugin_mode == "overlay" ? var.pod_cidr : null
    service_cidr        = var.service_cidr
    dns_service_ip      = var.dns_service_ip
  }

  dynamic "maintenance_window_auto_upgrade" {
    for_each = var.maintenance_window == null ? [] : [var.maintenance_window]

    content {
      frequency   = "Weekly"
      interval    = 1
      duration    = maintenance_window_auto_upgrade.value.duration_hours
      day_of_week = maintenance_window_auto_upgrade.value.day_of_week
      start_time  = maintenance_window_auto_upgrade.value.start_time
      utc_offset  = maintenance_window_auto_upgrade.value.utc_offset
    }
  }

  dynamic "maintenance_window_node_os" {
    for_each = var.maintenance_window == null ? [] : [var.maintenance_window]

    content {
      frequency   = "Weekly"
      interval    = 1
      duration    = maintenance_window_node_os.value.duration_hours
      day_of_week = maintenance_window_node_os.value.day_of_week
      start_time  = maintenance_window_node_os.value.start_time
      utc_offset  = maintenance_window_node_os.value.utc_offset
    }
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
    # The cluster autoscaler owns the live node count. Tracking it here would
    # produce a perpetual diff and let a routine apply scale the pool back down.
    ignore_changes = [default_node_pool[0].node_count]

    precondition {
      condition     = var.system_node_pool.min_count <= var.system_node_pool.node_count && var.system_node_pool.node_count <= var.system_node_pool.max_count
      error_message = "system_node_pool.node_count must be between min_count and max_count."
    }

    precondition {
      condition     = var.private_cluster_enabled || length(var.api_server_authorized_ip_ranges) > 0
      error_message = "A public AKS API server requires api_server_authorized_ip_ranges. Public exposure must be explicit and restricted."
    }
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  for_each = var.user_node_pools

  name                        = each.key
  kubernetes_cluster_id       = azurerm_kubernetes_cluster.this.id
  mode                        = "User"
  temporary_name_for_rotation = each.value.temporary_name_for_rotation
  vm_size                     = each.value.vm_size
  vnet_subnet_id              = coalesce(each.value.subnet_id, var.subnet_id)
  zones                       = each.value.zones != null ? each.value.zones : var.availability_zones
  auto_scaling_enabled        = true
  min_count                   = each.value.min_count
  max_count                   = each.value.max_count
  node_count                  = each.value.node_count
  max_pods                    = each.value.max_pods
  os_disk_size_gb             = each.value.os_disk_size_gb
  os_sku                      = each.value.os_sku
  priority                    = each.value.spot ? "Spot" : "Regular"
  eviction_policy             = each.value.spot ? "Delete" : null
  spot_max_price              = each.value.spot ? -1 : null
  node_labels                 = each.value.node_labels
  node_taints                 = each.value.spot ? concat(each.value.node_taints, ["kubernetes.azure.com/scalesetpriority=spot:NoSchedule"]) : each.value.node_taints
  tags                        = var.tags

  upgrade_settings {
    max_surge = each.value.max_surge
  }

  lifecycle {
    ignore_changes = [node_count]

    precondition {
      condition     = each.value.min_count <= each.value.node_count && each.value.node_count <= each.value.max_count
      error_message = "user_node_pools[${each.key}].node_count must be between min_count and max_count."
    }
  }
}

# Warn (not fail) when the system pool is tainted for critical add-ons but no
# user pool exists in this module: workloads would have nowhere to schedule
# unless the caller manages user pools elsewhere.
check "user_pool_available" {
  assert {
    condition     = !var.system_node_pool.only_critical_addons_enabled || length(var.user_node_pools) > 0
    error_message = "system_node_pool.only_critical_addons_enabled is true but user_node_pools is empty. Application pods will stay Pending unless user node pools are managed elsewhere."
  }
}
