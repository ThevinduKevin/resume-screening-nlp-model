variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

# GCP region - asia-south1 is Mumbai, same as AWS ap-south-1
variable "region" {
  default = "asia-south1"
}

# Machine type - e2-small has 2 vCPU (shared), 2GB RAM (comparable to t3.micro)
# e2-micro is too small (0.25 vCPU), e2-small is closer match
variable "machine_type" {
  default = "e2-small"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}
