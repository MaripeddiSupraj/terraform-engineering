# Destructive changes to stateful or foundational resources need an explicit,
# reviewed exception. Everything else that is destroyed is surfaced as a warning.
package main

import rego.v1

protected_types := {
	# Azure
	"azurerm_storage_account", "azurerm_storage_container", "azurerm_key_vault",
	"azurerm_key_vault_key", "azurerm_key_vault_secret", "azurerm_managed_disk",
	"azurerm_postgresql_flexible_server", "azurerm_postgresql_flexible_server_database",
	"azurerm_mysql_flexible_server", "azurerm_mssql_server", "azurerm_mssql_database",
	"azurerm_cosmosdb_account", "azurerm_redis_cache", "azurerm_container_registry",
	"azurerm_log_analytics_workspace", "azurerm_kubernetes_cluster",
	"azurerm_recovery_services_vault", "azurerm_data_protection_backup_vault",
	"azurerm_resource_group", "azurerm_virtual_network",
	# AWS
	"aws_s3_bucket", "aws_db_instance", "aws_rds_cluster", "aws_dynamodb_table",
	"aws_efs_file_system", "aws_ebs_volume", "aws_kms_key", "aws_eks_cluster",
	"aws_elasticache_replication_group", "aws_backup_vault", "aws_vpc",
	# GCP
	"google_sql_database_instance", "google_storage_bucket", "google_bigquery_dataset",
	"google_container_cluster", "google_kms_crypto_key", "google_spanner_instance",
	"google_compute_disk", "google_compute_network",
	# OCI
	"oci_database_autonomous_database", "oci_database_db_system", "oci_objectstorage_bucket",
	"oci_containerengine_cluster", "oci_kms_vault", "oci_core_vcn",
}

deny contains msg if {
	some rc in changes
	is_delete(rc)
	rc.type in protected_types
	not excepted("allow_destroy", rc.address)
	msg := sprintf(
		"%s: plan would %s a protected %s. Data or dependants may be lost. If intended, add the address to exceptions.allow_destroy in a reviewed change.",
		[rc.address, verb(rc), rc.type],
	)
}

warn contains msg if {
	some rc in changes
	is_delete(rc)
	not rc.type in protected_types
	msg := sprintf("%s: plan would %s this resource.", [rc.address, verb(rc)])
}
