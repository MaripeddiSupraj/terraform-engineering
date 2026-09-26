output "id" {
  description = "AKS cluster resource ID."
  value       = azurerm_kubernetes_cluster.this.id
}

output "name" {
  description = "AKS cluster name."
  value       = azurerm_kubernetes_cluster.this.name
}

output "principal_id" {
  description = "Principal ID of the AKS control-plane system-assigned managed identity."
  value       = azurerm_kubernetes_cluster.this.identity[0].principal_id
}

output "kubelet_identity_object_id" {
  description = "Object ID of the kubelet managed identity. Grant AcrPull on container registries to this identity."
  value       = try(azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id, null)
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL used by Azure Workload Identity federated credentials."
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "private_fqdn" {
  description = "Private API server FQDN when private-cluster mode is enabled."
  value       = azurerm_kubernetes_cluster.this.private_fqdn
}

output "node_resource_group" {
  description = "Name of the AKS-managed node resource group."
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}

output "user_node_pool_ids" {
  description = "User node pool resource IDs keyed by pool name."
  value       = { for name, pool in azurerm_kubernetes_cluster_node_pool.user : name => pool.id }
}
