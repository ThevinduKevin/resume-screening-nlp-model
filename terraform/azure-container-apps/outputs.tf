output "app_url" {
  description = "Container App URL"
  value       = "https://${azurerm_container_app.ml_api.ingress[0].fqdn}"
}

output "app_name" {
  description = "Container App name"
  value       = azurerm_container_app.ml_api.name
}

output "acr_login_server" {
  description = "ACR login server"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_name" {
  description = "ACR name"
  value       = azurerm_container_registry.acr.name
}

output "acr_admin_username" {
  description = "ACR admin username"
  value       = azurerm_container_registry.acr.admin_username
}

output "acr_admin_password" {
  description = "ACR admin password"
  value       = azurerm_container_registry.acr.admin_password
  sensitive   = true
}

output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.rg.name
}

output "location" {
  description = "Azure region"
  value       = var.location
}
