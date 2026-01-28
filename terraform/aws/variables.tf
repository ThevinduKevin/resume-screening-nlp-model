variable "region" {
  default = "ap-south-1"
}

variable "instance_type" {
  default = "t3.large"
}

variable "ami_id" {
  description = "AMI ID for Ubuntu 22.04"
  default     = "ami-0f5ee92e2d63afc18"
}  

variable "bucket_name" {
  description = "S3 bucket for ML files"
  default     = "resume-screening-ml-models-thevindu"
}

variable "ssh_public_key" {
  description = "SSH public key for EC2 access"
  type        = string
}