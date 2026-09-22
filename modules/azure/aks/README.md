# Azure Kubernetes Service

Opinionated AKS baseline for the reference platform.

## Security/operability defaults

- System-assigned managed identity
- Azure RBAC and Kubernetes RBAC
- Local accounts disabled
- OIDC issuer + Azure Workload Identity enabled
- Azure Policy enabled
- Private-cluster mode enabled by default
- Azure CNI + Azure network policy
- Autoscaling system node pool
- Optional Log Analytics integration using managed identity

The module intentionally does **not** output kubeconfig material.

Production callers should resolve a Kubernetes version currently supported in their target Azure region instead of relying permanently on Azure's implicit default.
