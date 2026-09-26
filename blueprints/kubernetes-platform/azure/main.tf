locals {
  base_name = "${var.project}-${var.environment}-${var.location_short}"

  common_tags = merge(var.tags, {
    environment = var.environment
    managed-by  = "terraform"
    project     = var.project
  })
}

module "resource_group" {
  source = "../../../modules/azure/resource-group"

  name     = "rg-${local.base_name}"
  location = var.location
  tags     = local.common_tags
}

module "network" {
  source = "../../../modules/azure/network"

  name                = "vnet-${local.base_name}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  address_space       = var.address_space
  subnets = {
    aks = {
      address_prefixes = var.aks_subnet_prefixes
    }
  }
  tags = local.common_tags
}

module "monitoring" {
  source = "../../../modules/azure/log-analytics"

  name                = "log-${local.base_name}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  retention_in_days   = var.log_retention_days
  tags                = local.common_tags
}

module "aks" {
  source = "../../../modules/azure/aks"

  name                            = "aks-${local.base_name}"
  resource_group_name             = module.resource_group.name
  location                        = module.resource_group.location
  dns_prefix                      = "aks-${local.base_name}"
  kubernetes_version              = var.kubernetes_version
  subnet_id                       = module.network.subnet_ids["aks"]
  private_cluster_enabled         = var.private_cluster_enabled
  api_server_authorized_ip_ranges = var.api_server_authorized_ip_ranges
  admin_group_object_ids          = var.aks_admin_group_object_ids
  availability_zones              = var.availability_zones
  system_node_pool                = var.system_node_pool
  user_node_pools                 = var.user_node_pools
  maintenance_window              = var.maintenance_window
  log_analytics_workspace_id      = module.monitoring.id
  tags                            = local.common_tags
}
