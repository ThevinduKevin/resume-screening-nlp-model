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
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

provider "aws" {
  region = var.region
}

# Grant Lambda permissions to the Terraform user (needed for creating/managing Lambda resources)
resource "aws_iam_user_policy" "terraform_lambda_permissions" {
  name = "lambda-management-permissions"
  user = "github-terraform-user"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:*",
          "iam:PassRole"
        ]
        Resource = "*"
      }
    ]
  })
}

# Wait for IAM policy to propagate (AWS eventual consistency)
resource "time_sleep" "wait_for_iam_propagation" {
  depends_on      = [aws_iam_user_policy.terraform_lambda_permissions]
  create_duration = "15s"
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

# Clean up any pre-existing IAM role (fresh state won't know about it)
resource "terraform_data" "cleanup_iam" {
  provisioner "local-exec" {
    command = <<-EOT
      aws iam detach-role-policy --role-name ml-resume-lambda-role --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole 2>/dev/null || true
      aws iam delete-role --role-name ml-resume-lambda-role 2>/dev/null || true
    EOT
  }
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

  depends_on = [terraform_data.cleanup_iam]
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
  architectures = ["x86_64"]

  environment {
    variables = {
      ENVIRONMENT = "serverless"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic,
    time_sleep.wait_for_iam_propagation
  ]

  lifecycle {
    ignore_changes = [image_uri]
  }
}

# API Gateway HTTP API
resource "aws_apigatewayv2_api" "lambda_api" {
  name          = "ml-resume-api-gateway"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST"]
    allow_headers = ["*"]
  }
  depends_on = [time_sleep.wait_for_iam_propagation]
}

resource "aws_apigatewayv2_stage" "lambda_stage" {
  api_id      = aws_apigatewayv2_api.lambda_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id             = aws_apigatewayv2_api.lambda_api.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.ml_api.invoke_arn
}

resource "aws_apigatewayv2_route" "lambda_route" {
  api_id    = aws_apigatewayv2_api.lambda_api.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Permission for API Gateway to invoke Lambda
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ml_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.lambda_api.execution_arn}/*/*"
}
