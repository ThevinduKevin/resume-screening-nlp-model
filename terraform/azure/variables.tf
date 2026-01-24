variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

# Azure region - Central US typically has better capacity
variable "location" {
  default = "Central US"
}

# VM size - Standard_D2s_v3 (2 vCPU, 8GB RAM)
variable "vm_size" {
  default = "Standard_D2s_v3"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}
