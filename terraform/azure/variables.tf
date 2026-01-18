variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

# Azure region - UK South typically has excellent VM availability
variable "location" {
  default = "UK South"
}

# VM size - Standard_D2s_v3 (2 vCPU, 8GB) is widely available
# D-series v3 has better availability than B-series and older D-series
variable "vm_size" {
  default = "Standard_D2s_v3"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}
