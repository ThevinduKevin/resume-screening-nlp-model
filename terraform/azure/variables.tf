variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

# Azure region - Southeast Asia where user has quota
variable "location" {
  default = "Southeast Asia"
}

# VM size - Standard_DS1_v2 (1 vCPU, 3.5GB RAM) - D-series is more available
variable "vm_size" {
  default = "Standard_DS1_v2"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}
