variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

# Azure region - West US 2 typically has good B-series availability
variable "location" {
  default = "West US 2"
}

# VM size - Standard_B1s (1 vCPU, 1GB) is more widely available than B1ms
# Comparable to AWS t3.micro (2 vCPU, 1GB) and GCP e2-small (2 vCPU, 2GB)
variable "vm_size" {
  default = "Standard_B1s"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}
