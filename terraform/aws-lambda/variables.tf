variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "function_name" {
  description = "Lambda function name"
  type        = string
  default     = "ml-resume-api"
}

variable "memory_size" {
  description = "Lambda memory size in MB"
  type        = number
  default     = 2048  # 2GB for ML model
}
