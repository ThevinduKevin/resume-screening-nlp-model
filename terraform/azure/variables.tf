variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

# Azure region - Sweden Central is a newer region with good capacity
variable "location" {
  default = "Sweden Central"
}

# VM size - Standard_B2s (2 vCPU, 4GB) - trying B-series in a different region
# If this fails, may need to check Azure subscription quotas
variable "vm_size" {
  default = "Standard_B2s"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}
