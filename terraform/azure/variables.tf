variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

# Azure region - Central US typically has better capacity
variable "location" {
  default = "Central US"
}

# VM size 
variable "vm_size" {
  default = "B2ats_v2"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}
