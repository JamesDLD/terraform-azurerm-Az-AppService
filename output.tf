# -
# - App Service 
# -

output "app_services" {
  description = "Map output of the App Services"
  value       = { for k, b in azurerm_app_service.apps1 : k => b }
}

# -
# - App Service - Map outputs
# -

output "app_service_plans" {
  description = "Map output of the App Service Plans"
  value       = { for k, b in azurerm_app_service_plan.asp1 : k => b }
}

