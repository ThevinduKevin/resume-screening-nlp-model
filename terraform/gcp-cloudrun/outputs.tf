output "service_url" {
  description = "Cloud Run service URL"
  value       = google_cloud_run_v2_service.ml_api.uri
}

output "service_name" {
  description = "Cloud Run service name"
  value       = google_cloud_run_v2_service.ml_api.name
}

output "artifact_registry_url" {
  description = "Artifact Registry URL"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.ml_repo.repository_id}"
}

output "region" {
  description = "GCP region"
  value       = var.region
}

output "project_id" {
  description = "GCP Project ID"
  value       = var.project_id
}
