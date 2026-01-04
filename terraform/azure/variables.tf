variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

# Azure region - Central India is closest to ap-south-1 (Mumbai)
variable "location" {
  default = "Central India"
}

# VM size - Standard_B2s has 2 vCPU, 4GB RAM (comparable to t3.micro which has 2 vCPU, 1GB)
# For exact match to t3.micro (2 vCPU, 1GB), use Standard_B1ms
variable "vm_size" {
  default = "Standard_B1ms"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}
