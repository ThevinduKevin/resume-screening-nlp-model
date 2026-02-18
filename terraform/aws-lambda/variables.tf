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
  description = "Lambda memory size in MB (CPU allocated proportionally)"
  type        = number
  default     = 3008 # 3GB Memory (Max allowed for new accounts/regions sometimes)
}
