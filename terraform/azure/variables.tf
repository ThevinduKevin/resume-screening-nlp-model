variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

# Azure region - North Europe typically has good VM availability
variable "location" {
  default = "North Europe"
}

# VM size - Standard_DS1_v2 (1 vCPU, 3.5GB) is more widely available than B-series
# B-series often has capacity restrictions
variable "vm_size" {
  default = "Standard_DS1_v2"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}
