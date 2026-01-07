# Variables for Cloud Security Week 3 Assignment

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-2"
}

variable "availability_zone" {
  description = "Availability Zone"
  type        = string
  default     = "ap-northeast-2a"
}

variable "vpc_cidr" {
  description = "VPC CIDR Block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Public Subnet CIDR Block"
  type        = string
  default     = "10.0.1.0/24"
}

variable "ami_id" {
  description = "AMI ID for EC2 Instance"
  type        = string
  default     = "ami-04fcc2023d6e37430"
}

variable "instance_type" {
  description = "EC2 Instance Type"
  type        = string
  default     = "t2.micro"
}

variable "s3_bucket_name" {
  description = "S3 Bucket Name for SSM Logs"
  type        = string
  default     = "hdy-s3-for-cs-project"
}

variable "cloudflare_token" {
  description = "Cloudflare Tunnel Token"
  type        = string
  sensitive   = true
}