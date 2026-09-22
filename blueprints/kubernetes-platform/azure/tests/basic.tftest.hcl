mock_provider "azurerm" {}

run "platform_composition" {
  command = plan

  variables {
    project                    = "payments"
    environment                = "prod"
    location                   = "centralindia"
    location_short             = "ci"
    address_space              = ["10.20.0.0/16"]
    aks_subnet_prefixes        = ["10.20.0.0/20"]
    aks_admin_group_object_ids = [
      "11111111-1111-1111-1111-111111111111"
    ]
  }

  assert {
    condition     = module.aks.name == "aks-payments-prod-ci"
    error_message = "Blueprint naming contract changed unexpectedly."
  }
}
