variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

# Azure region - East US has good VM capacity for Pay-As-You-Go
variable "location" {
  default = "East US"
}

# VM size - Standard_B2s (2 vCPU, 4GB RAM)
variable "vm_size" {
  default = "Standard_B2s"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}
