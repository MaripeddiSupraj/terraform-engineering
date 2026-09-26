resource "terraform_data" "app" {
  input = {
    name        = "smoke-app"
    environment = var.environment
  }
}

resource "terraform_data" "cache" {
  count = var.cache_enabled ? 1 : 0

  input = {
    name        = "smoke-cache"
    environment = var.environment
  }
}
