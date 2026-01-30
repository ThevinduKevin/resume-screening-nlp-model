variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

# Azure region - Central US typically has better capacity
variable "location" {
  default = "Central US"
}

# VM size - Standard_B2s (2 vCPU burstable, 4GB RAM) - comparable to AWS t3.micro / GCP e2-small
variable "vm_size" {
  default = "Standard_D2s_v3"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}
