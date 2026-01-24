variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

# Azure region - Central US typically has better capacity
variable "location" {
  default = "Central US"
}

# VM size - Standard_A1_v2 (1 vCPU, 2GB RAM) - A-series is older and more available
variable "vm_size" {
  default = "Standard_A1_v2"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}
