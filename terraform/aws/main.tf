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

resource "aws_instance" "ml_vm" {
  ami           = var.ami_id
  instance_type = var.instance_type

  user_data = file("${path.module}/user_data.sh")

  vpc_security_group_ids = [aws_security_group.ml_sg.id]

  tags = {
    Name = "ml-research-vm"
  }
}

