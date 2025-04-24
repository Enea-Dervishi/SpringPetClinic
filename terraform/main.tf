terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev/staging/prod)"
  type        = string
}

locals {
  name_prefix = "petclinic-${var.environment}"
}

# VPC Configuration
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

# Subnet Configuration
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "${local.name_prefix}-public-subnet"
  }
}

# Security Group for Application
resource "aws_security_group" "app" {
  name        = "${local.name_prefix}-app-sg"
  description = "Security group for PetClinic application"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 8080
    to_port     = 8080
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

  tags = {
    Name = "${local.name_prefix}-app-sg"
  }
}

# EC2 Instance for Application
resource "aws_instance" "app" {
  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id

  vpc_security_group_ids = [aws_security_group.app.id]

  tags = {
    Name = "${local.name_prefix}-app-server"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y java-1.8.0-openjdk
              EOF
}

# RDS Instance for Database
resource "aws_db_instance" "petclinic" {
  identifier           = "${local.name_prefix}-db"
  engine              = "mysql"
  engine_version      = "5.7"
  instance_class      = "db.t2.micro"
  allocated_storage   = 20
  storage_type        = "gp2"
  username            = "petclinic"
  password            = "petclinic"
  skip_final_snapshot = true

  vpc_security_group_ids = [aws_security_group.app.id]
  db_subnet_group_name   = aws_db_subnet_group.petclinic.name

  tags = {
    Name = "${local.name_prefix}-db"
  }
}

resource "aws_db_subnet_group" "petclinic" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = [aws_subnet.public.id]

  tags = {
    Name = "${local.name_prefix}-db-subnet-group"
  }
} 