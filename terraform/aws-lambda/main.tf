terraform {
  backend "gcs" {
    bucket = "resume-screening-ml-terraform-bucket"
    prefix = "aws-lambda-v2"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# ECR Repository for Lambda container
# Clean up any pre-existing ECR repo (fresh state won't know about it)
resource "terraform_data" "cleanup_ecr" {
  provisioner "local-exec" {
    command = "aws ecr delete-repository --repository-name ml-resume-lambda --force 2>/dev/null || true"
  }
}

resource "aws_ecr_repository" "lambda_repo" {
  name                 = "ml-resume-lambda"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = false
  }

  depends_on = [terraform_data.cleanup_ecr]
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "ml-resume-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for Lambda
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

# Lambda Function (placeholder - will be deployed after image push)
resource "aws_lambda_function" "ml_api" {
  function_name = var.function_name
  role          = aws_iam_role.lambda_role.arn
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.lambda_repo.repository_url}:latest"
  timeout       = 300
  memory_size   = var.memory_size

  environment {
    variables = {
      ENVIRONMENT = "serverless"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic
  ]

  lifecycle {
    ignore_changes = [image_uri]
  }
}

# Lambda Function URL (simpler than API Gateway for benchmarking)
resource "aws_lambda_function_url" "ml_api_url" {
  function_name      = aws_lambda_function.ml_api.function_name
  authorization_type = "NONE"

  cors {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST"]
    allow_headers = ["*"]
  }
}

# API Gateway (alternative to Function URL for more control)
resource "aws_apigatewayv2_api" "lambda_api" {
  name          = "ml-resume-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["*"]
  }
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.lambda_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.ml_api.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "health" {
  api_id    = aws_apigatewayv2_api.lambda_api.id
  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "predict" {
  api_id    = aws_apigatewayv2_api.lambda_api.id
  route_key = "POST /predict"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.lambda_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ml_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.lambda_api.execution_arn}/*/*"
}
