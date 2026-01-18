variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

# Azure region - Germany West Central typically has good availability
variable "location" {
  default = "Germany West Central"
}

# VM size - Standard_A2_v2 (2 vCPU, 4GB) is the most widely available
# A-series v2 has best availability across all Azure regions
variable "vm_size" {
  default = "Standard_A2_v2"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}
