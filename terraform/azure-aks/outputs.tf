output "cluster_name" {
  description = "AKS Cluster Name"
  value       = azurerm_kubernetes_cluster.main.name
}

output "resource_group_name" {
  description = "Resource Group Name"
  value       = azurerm_resource_group.main.name
}

output "acr_name" {
  description = "ACR Name"
  value       = azurerm_container_registry.acr.name
}

output "acr_login_server" {
  description = "ACR Login Server"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_admin_username" {
  description = "ACR Admin Username"
  value       = azurerm_container_registry.acr.admin_username
}

output "acr_admin_password" {
  description = "ACR Admin Password"
  value       = azurerm_container_registry.acr.admin_password
  sensitive   = true
}

output "kube_config" {
  description = "Kubernetes config"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}
