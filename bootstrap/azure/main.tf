resource "azurerm_resource_group" "state" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_storage_account" "state" {
  name                              = var.storage_account_name
  resource_group_name               = azurerm_resource_group.state.name
  location                          = azurerm_resource_group.state.location
  account_tier                      = "Standard"
  account_replication_type          = var.replication_type
  min_tls_version                   = "TLS1_2"
  https_traffic_only_enabled        = true
  infrastructure_encryption_enabled = true
  cross_tenant_replication_enabled  = false
  allowed_copy_scope                = "AAD"
  local_user_enabled                = false
  allow_nested_items_to_be_public   = false
  public_network_access_enabled     = var.public_network_access_enabled

  # State is read and written with Entra ID only. Account keys and SAS tokens
  # are long-lived bearer credentials that cannot be scoped to one pipeline.
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
    ip_rules       = var.allowed_ip_rules
  }

  blob_properties {
    versioning_enabled  = true
    change_feed_enabled = true

    delete_retention_policy {
      days = var.soft_delete_retention_days
    }

    container_delete_retention_policy {
      days = var.soft_delete_retention_days
    }
  }

  tags = var.tags

  lifecycle {
    # Losing the state account orphans every environment that uses it.
    prevent_destroy = true
  }
}

resource "azurerm_storage_container" "state" {
  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"

  lifecycle {
    prevent_destroy = true
  }
}

# A delete lock also protects against deletion outside Terraform (portal, CLI,
# or a resource-group delete).
resource "azurerm_management_lock" "state" {
  count = var.delete_lock_enabled ? 1 : 0

  name       = "lock-${var.storage_account_name}"
  scope      = azurerm_storage_account.state.id
  lock_level = "CanNotDelete"
  notes      = "Terraform remote state. Remove only through a reviewed change."
}

# Pipelines and operators that run plan/apply need data-plane access because
# shared keys are disabled. Keyed by a stable label so adding or removing one
# principal never recreates the others.
resource "azurerm_role_assignment" "state_writers" {
  for_each = var.state_writer_principals

  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.value.principal_id
  principal_type       = each.value.principal_type
  description          = "Terraform state read/write for ${each.key}."
}
