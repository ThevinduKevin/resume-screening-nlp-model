variable "location" {
  default = "Central India"
}

variable "vm_size" {
  default = "Standard_B1s"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}
