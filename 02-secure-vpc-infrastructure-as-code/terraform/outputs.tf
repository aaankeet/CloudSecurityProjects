output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "public_subnets_ids" {
  description = "Public Subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnets_ids" {
  description = "Public Subnet IDs"
  value       = aws_subnet.private[*].id
}

output "data_subnets_ids" {
  description = "Public Subnet IDs"
  value       = aws_subnet.data[*].id
}

# ALB Security Group
output "alb_security_group_id" {
  description = "ALB Security Group ID"
  value       = aws_security_group.alb.id
}

# App Security Group
output "app_security_group_id" {
  description = "App Security Group ID"
  value       = aws_security_group.app.id
}

# DB Security Group
output "db_security_group_id" {
  description = "DB Security Group ID"
  value       = aws_security_group.db.id
}

# Flow Logs Log Group
output "flow_logs_log_group" {
  description = "CloudWatch Log Group for VPC Flow Logs"
  value       = aws_cloudwatch_log_group.vpc_flow_logs.name
}

# VPC Endpoints
output "s3_endpoint_id" {
  value = aws_vpc_endpoint.s3.id
}

output "cloudwatch_logs_endpoint_id" {
  value = aws_vpc_endpoint.cloudwatch_logs.id
}
