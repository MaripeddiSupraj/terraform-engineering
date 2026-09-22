output "id" {
  description = "AKS cluster resource ID."
  value       = azurerm_kubernetes_cluster.this.id
}

output "name" {
  description = "AKS cluster name."
  value       = azurerm_kubernetes_cluster.this.name
}

output "principal_id" {
  description = "Principal ID of the AKS system-assigned managed identity."
  value       = azurerm_kubernetes_cluster.this.identity[0].principal_id
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL used by Azure Workload Identity."
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "private_fqdn" {
  description = "Private API server FQDN when private-cluster mode is enabled."
  value       = azurerm_kubernetes_cluster.this.private_fqdn
}
