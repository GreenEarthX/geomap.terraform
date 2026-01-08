# terraform-geomap/outputs.tf
# ECR Repository Output
output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.geomap.repository_url
}

# Application URL - using Route53 DNS
output "application_url" {
  description = "URL of the geomap application"
  value       = "https://${aws_route53_record.geomap.name}"
}

# Load Balancer DNS (shared ALB)
output "load_balancer_dns" {
  description = "DNS name of the shared load balancer"
  value       = data.terraform_remote_state.shared.outputs.shared_alb_dns_name
}

# Database Endpoint
output "database_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.geomap.endpoint
  sensitive   = true
}

# GitHub Actions Access Keys
output "github_actions_access_key_id" {
  description = "Access Key ID for GitHub Actions"
  value       = aws_iam_access_key.github_actions.id
  sensitive   = true
}

output "github_actions_secret_access_key" {
  description = "Secret Access Key for GitHub Actions"
  value       = aws_iam_access_key.github_actions.secret
  sensitive   = true
}
