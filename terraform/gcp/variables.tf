variable "project_id" {}
variable "region" {
  default = "asia-south1"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}
