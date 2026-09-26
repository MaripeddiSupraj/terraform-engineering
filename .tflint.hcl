config {
  format = "compact"
  # Lint module calls from blueprints too, so a bad argument is caught where it is used.
  call_module_type = "local"
}

plugin "terraform" {
  enabled = true
  preset  = "all"
}

plugin "azurerm" {
  enabled = true
  version = "0.32.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

# Workspaces are not used by this framework; environments are separate roots/state keys.
rule "terraform_workspace_remote" {
  enabled = false
}
