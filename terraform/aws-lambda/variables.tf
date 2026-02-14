variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "function_name" {
  description = "Lambda function name"
  type        = string
  default     = "ml-resume-api"
}

variable "memory_size" {
  description = "Lambda memory size in MB (CPU allocated proportionally)"
  type        = number
  default     = 8192
}
