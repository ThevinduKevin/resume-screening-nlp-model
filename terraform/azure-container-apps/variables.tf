variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "centralindia"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "ml-serverless-rg"
}

variable "acr_name" {
  description = "Azure Container Registry name (must be globally unique)"
  type        = string
  default     = "mlresumeserverlessacr"
}

variable "app_name" {
  description = "Container App name"
  type        = string
  default     = "ml-resume-api"
}

variable "cpu_cores" {
  description = "CPU cores for the container"
  type        = number
  default     = 2.0 # 2 vCPU to match VM/K8s
}

variable "memory_size" {
  description = "Memory size for the container"
  type        = string
  default     = "8Gi"
}

variable "min_replicas" {
  description = "Minimum number of replicas"
  type        = number
  default     = 0 # Scale to zero
}

variable "max_replicas" {
  description = "Maximum number of replicas"
  type        = number
  default     = 10
}
