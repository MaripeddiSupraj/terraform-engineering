output "resource_group_name" {
  description = "Platform resource group name."
  value       = module.resource_group.name
}

output "virtual_network_id" {
  description = "Platform virtual network resource ID."
  value       = module.network.id
}

output "aks_cluster_id" {
  description = "AKS cluster resource ID."
  value       = module.aks.id
}

output "aks_cluster_name" {
  description = "AKS cluster name."
  value       = module.aks.name
}

output "aks_oidc_issuer_url" {
  description = "AKS OIDC issuer URL for workload identity federation."
  value       = module.aks.oidc_issuer_url
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace resource ID."
  value       = module.monitoring.id
}
