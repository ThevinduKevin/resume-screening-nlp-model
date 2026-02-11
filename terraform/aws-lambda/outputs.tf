output "ecr_repository_url" {
  description = "ECR repository URL for Lambda container"
  value       = aws_ecr_repository.lambda_repo.repository_url
}

output "function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.ml_api.function_name
}

output "function_url" {
  description = "Lambda function URL"
  value       = aws_lambda_function_url.ml_api_url.function_url
}

output "api_gateway_url" {
  description = "API Gateway URL"
  value       = aws_apigatewayv2_api.lambda_api.api_endpoint
}

output "region" {
  description = "AWS region"
  value       = var.region
}
