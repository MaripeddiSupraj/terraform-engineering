# Azure Kubernetes Platform Blueprint

Reference composition showing how the framework expects agents and humans to build infrastructure: **compose reviewed modules instead of generating an entire platform from scratch**.

It creates:

- resource group;
- virtual network + AKS subnet;
- Log Analytics workspace;
- AKS cluster with private-cluster mode by default.

## Important production considerations

This first reference intentionally stops before pretending to solve every enterprise topology. Production designs commonly still need private DNS/hub-spoke connectivity, firewall/NAT routing, private endpoints, ingress, workload-specific node pools, backup, Defender/Prometheus decisions, and organization-specific RBAC.

Those should be added as reviewed modules—not hidden ad-hoc code inside this blueprint.
