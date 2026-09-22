# Azure Key Vault

Secure baseline Key Vault using Azure RBAC authorization, soft delete, purge protection, and explicit default-deny network ACLs. Public network access defaults to disabled; callers that enable it must explicitly allow trusted IPs/subnets. Private deployments should compose private endpoint/DNS connectivity.
