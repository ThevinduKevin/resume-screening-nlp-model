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

output "zone" {
  description = "GKE Cluster Zone"
  value       = var.zone
}

output "project_id" {
  description = "GCP Project ID"
  value       = var.project_id
}

output "artifact_registry_url" {
  description = "Artifact Registry URL"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/ml-resume-gke-repo"
}
