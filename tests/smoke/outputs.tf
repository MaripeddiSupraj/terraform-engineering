output "app" {
  description = "Echo of the app resource input."
  value       = terraform_data.app.output
}
