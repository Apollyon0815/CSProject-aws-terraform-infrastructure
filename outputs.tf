# Outputs for Cloud Security Week 3 Assignment

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.csvpc.id
}

output "public_subnet_id" {
  description = "Public Subnet ID"
  value       = aws_subnet.public_subnet.id
}

output "ec2_instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.web_server.id
}

output "ec2_public_ip" {
  description = "EC2 Instance Public IP"
  value       = aws_instance.web_server.public_ip
}

output "security_group_id" {
  description = "Security Group ID"
  value       = aws_security_group.web_sg.id
}

output "s3_bucket_name" {
  description = "S3 Bucket Name"
  value       = aws_s3_bucket.ssm_logs.bucket
}

output "iam_role_name" {
  description = "IAM Role Name"
  value       = aws_iam_role.ec2_ssm_role.name
}

output "web_server_url" {
  description = "Web Server URL"
  value       = "http://${aws_instance.web_server.public_ip}"
}
