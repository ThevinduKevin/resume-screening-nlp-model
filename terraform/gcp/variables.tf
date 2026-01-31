variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

# GCP region - asia-south1 is Mumbai, same as AWS ap-south-1
variable "region" {
  default = "asia-south1"
}

# Machine type - e2-standard-2 (2 vCPU, 8GB RAM) - comparable to Azure Standard_D2s_v3 / AWS t3.large
variable "machine_type" {
  default = "e2-standard-2"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}
