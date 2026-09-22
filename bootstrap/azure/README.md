# Azure Terraform State Bootstrap

Creates the storage resources required by an AzureRM remote backend.

## Bootstrap sequence

This root configuration starts with local Terraform state because the remote backend does not exist yet.

```bash
cp terraform.tfvars.example terraform.tfvars
# edit the globally unique storage account name
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Then configure target root modules with an `azurerm` backend using Microsoft Entra/OIDC authentication. Do not commit storage account keys.

`public_network_access_enabled` defaults to true because a brand-new bootstrap commonly lacks private CI networking, but the storage firewall is **default deny**. Add only the trusted bootstrap runner egress IP/CIDR to `allowed_ip_rules`. Prefer private connectivity and set public network access to false for steady-state use.
