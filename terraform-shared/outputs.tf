# terraform-shared/outputs.tf
# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# Subnet Outputs
output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = aws_subnet.database[*].id
}

output "db_subnet_group_name" {
  description = "Name of the database subnet group"
  value       = aws_db_subnet_group.main.name
}

# Security Group Outputs
output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "ID of the ECS security group"
  value       = aws_security_group.ecs.id
}

output "rds_security_group_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds.id
}

# Route53 Outputs
 output "domain_name" {
   description = "The domain name"
   value       = var.domain_name
 }

# Other Outputs
output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = aws_instance.bastion.public_ip
}

output "bastion_security_group_id" {
  description = "Security group ID of the bastion host"
  value       = aws_security_group.bastion.id
}

# ALB Outputs
output "shared_alb_arn" {
  description = "ARN of the shared Application Load Balancer"
  value       = aws_lb.shared.arn
}

output "shared_alb_dns_name" {
  description = "DNS name of the shared ALB"
  value       = aws_lb.shared.dns_name
}

output "shared_alb_zone_id" {
  description = "Zone ID of the shared ALB"
  value       = aws_lb.shared.zone_id
}

output "shared_alb_https_listener_arn" {
  description = "ARN of the shared ALB HTTPS listener"
  value       = aws_lb_listener.https.arn
}

output "acm_certificate_arn" {
  description = "ARN of the wildcard ACM certificate"
  value       = aws_acm_certificate_validation.wildcard.certificate_arn
}

# GitHub Actions OIDC Outputs
output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions IAM role for deployments"
  value       = aws_iam_role.github_actions.arn
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}