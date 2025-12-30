provider "aws" {
  region = var.region
}

resource "aws_security_group" "ml_sg" {
  name = "ml-sg"

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

resource "aws_instance" "ml" {
  ami           = "ami-0f5ee92e2d63afc18" # Ubuntu 22.04 ap-south-1
  instance_type = var.instance_type
  key_name      = var.key_name
  security_groups = [aws_security_group.ml_sg.name]

  tags = {
    Name = "ml-benchmark-aws"
  }
}
