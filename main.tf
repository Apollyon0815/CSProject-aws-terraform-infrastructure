# Terraform Configuration for Cloud Security Week 3 Assignment
# Provider Configuration
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "csvpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "CSVPC-1"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.csvpc.id

  tags = {
    Name = "CSVPC-1-IGW"
  }
}

# Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.csvpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "CSVPC-1-A"
  }
}

# Route Table for Public Subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.csvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "CSVPC-1-Public-RT"
  }
}

# Route Table Association
resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Network ACL
resource "aws_network_acl" "subnet_acl" {
  vpc_id     = aws_vpc.csvpc.id
  subnet_ids = [aws_subnet.public_subnet.id]

  # Inbound Rules
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 105
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Outbound Rules
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "Subnet-ACL"
  }
}

# Security Group for Web Server
resource "aws_security_group" "web_sg" {
  name        = "CS-SecurityGroup-Forweb"
  description = "Security group for web server"
  vpc_id      = aws_vpc.csvpc.id

  # Inbound Rules
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound Rules
  egress {
    description = "All traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "CS-SecurityGroup-Forweb"
  }
}

# IAM Role for EC2
resource "aws_iam_role" "ec2_ssm_role" {
  name = "CS-Role-EC2-SSM"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "CS-Role-EC2-SSM"
  }
}

# Attach SSM Policy to IAM Role
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# [리팩토링] S3 FullAccess와 ReadOnly를 삭제하고, 이 버킷에만 접근하는 인라인 정책 추가
resource "aws_iam_role_policy" "s3_access_policy" {
  name = "CS-S3-Log-Access"
  role = aws_iam_role.ec2_ssm_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:GetEncryptionConfiguration"
        ]
        Effect   = "Allow"
        Resource = [
          "${aws_s3_bucket.ssm_logs.arn}",
          "${aws_s3_bucket.ssm_logs.arn}/*"
        ]
      }
    ]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "CS-EC2-Instance-Profile"
  role = aws_iam_role.ec2_ssm_role.name
}

# S3 Bucket for SSM Logs
resource "aws_s3_bucket" "ssm_logs" {
  bucket = var.s3_bucket_name
  force_destroy = true

  tags = {
    Name = "CS-SSM-Logs-Bucket"
  }
}

# S3 Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "ssm_logs_encryption" {
  bucket = aws_s3_bucket.ssm_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "ssm_logs_versioning" {
  bucket = aws_s3_bucket.ssm_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

# EC2 Instance
resource "aws_instance" "web_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
              #!/bin/bash
              # Update system
              yum update -y

              # Install Nginx
              sudo yum install nginx -y

              # Start and enable Nginx
              systemctl start nginx
              systemctl enable nginx

              # When Nginx installed, show this
              echo <h1>Terraform 리팩토링 ver.2 배포 성공</h1><p><Nginx 자동 설치 완료/p>

              # Configure firewall
              systemctl status nginx
              EOF

  tags = {
    Name = "CS-Web-Server-For-Nginx-Practice"
  }
}
