variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

# GCP region - asia-south1 is Mumbai, same as AWS ap-south-1
variable "region" {
  default = "asia-south1"
}

# Machine type - e2-medium (2 vCPU shared, 4GB RAM) - comparable to AWS t3.small / Azure B2s
variable "machine_type" {
  default = "e2-medium"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}
