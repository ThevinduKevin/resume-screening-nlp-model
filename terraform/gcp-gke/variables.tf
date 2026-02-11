variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "asia-south1"
}

variable "zone" {
  description = "GCP zone for zonal cluster (avoids multi-zone capacity issues)"
  type        = string
  default     = "asia-south1-a"
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
  default     = "ml-benchmark-gke"
}

variable "node_machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-standard-2"
}
