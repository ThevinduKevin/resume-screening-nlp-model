variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

# Azure region - East US typically has good capacity
variable "location" {
  default = "East US"
}

# VM size - Standard_B2s (2 vCPU, 4GB RAM)
# Comparable to AWS t3.micro and GCP e2-micro
variable "vm_size" {
  default = "Standard_B2s"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}
