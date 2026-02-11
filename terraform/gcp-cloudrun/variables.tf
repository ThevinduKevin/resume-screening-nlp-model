variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "asia-south1"
}

variable "service_name" {
  description = "Cloud Run service name"
  type        = string
  default     = "ml-resume-api"
}

variable "cpu_limit" {
  description = "CPU limit for Cloud Run"
  type        = string
  default     = "2"  # 2 vCPUs
}

variable "memory_limit" {
  description = "Memory limit for Cloud Run"
  type        = string
  default     = "4Gi"  # 4GB for ML model
}

variable "min_instances" {
  description = "Minimum number of instances"
  type        = number
  default     = 0  # Scale to zero for true serverless
}

variable "max_instances" {
  description = "Maximum number of instances"
  type        = number
  default     = 10
}
