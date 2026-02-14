output "ecr_repository_url" {
  description = "ECR repository URL for Lambda container"
  value       = aws_ecr_repository.lambda_repo.repository_url
}

output "function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.ml_api.function_name
}

output "function_url" {
  description = "The URL of the API Gateway"
  value       = aws_apigatewayv2_stage.lambda_stage.invoke_url
}



output "region" {
  description = "AWS region"
  value       = var.region
}
