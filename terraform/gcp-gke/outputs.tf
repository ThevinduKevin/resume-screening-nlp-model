output "cluster_name" {
  description = "GKE Cluster Name"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "GKE Cluster Endpoint"
  value       = google_container_cluster.primary.endpoint
}

output "region" {
  description = "GKE Cluster Region"
  value       = var.region
}

output "project_id" {
  description = "GCP Project ID"
  value       = var.project_id
}
