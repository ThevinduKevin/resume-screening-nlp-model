terraform {
  backend "gcs" {
    bucket = "resume-screening-ml-terraform-bucket"
    prefix = "aws"
  }
}

provider "aws" {
  region = var.region
}

# SSH KEY PAIR (from GitHub Actions)
resource "aws_key_pair" "deployer" {
  key_name   = "ml-deployer-key"
  public_key = var.ssh_public_key
}

# SECURITY GROUP
resource "aws_security_group" "ml_sg" {
  name = "ml-sg-tf"

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# S3 BUCKET (FOR LARGE FILES)
# resource "aws_s3_bucket" "ml_bucket" {
#   bucket        = var.bucket_name
#   force_destroy = true
# }

# IAM ROLE FOR EC2 → S3 ACCESS
resource "aws_iam_role" "ec2_role" {
  name = "ec2-s3-role-tf-v2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "s3_policy" {
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:ListBucket"
      ]
      Resource = [
        "arn:aws:s3:::resume-screening-ml-models-thevindu",
        "arn:aws:s3:::resume-screening-ml-models-thevindu/*"
      ]
    }]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-s3-profile-tf-v2"
  role = aws_iam_role.ec2_role.name
}

# EC2 INSTANCE
resource "aws_instance" "ml_vm" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.ml_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  key_name               = aws_key_pair.deployer.key_name

  user_data = file("${path.module}/user_data.sh")

  tags = {
    Name = "ml-research-vm"
  }
}


