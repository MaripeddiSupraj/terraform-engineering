terraform {
  required_version = "= 1.16.3"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 5.4.0"
    }
  }
}

provider "azurerm" {
  # Shared keys are disabled on the state account, so every data-plane call
  # must use Entra ID.
  storage_use_azuread = true

  features {}
}
