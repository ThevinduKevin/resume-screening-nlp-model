variable "location" {
  description = "Azure region"
  type        = string
  default     = "Southeast Asia"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "ml-benchmark-rg"
}

variable "cluster_name" {
  description = "AKS cluster name"
  type        = string
  default     = "ml-benchmark-aks"
}

variable "acr_name" {
  description = "Azure Container Registry name (must be globally unique)"
  type        = string
  default     = "mlbenchmarkacr"
}

variable "node_vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_B2s"
}
