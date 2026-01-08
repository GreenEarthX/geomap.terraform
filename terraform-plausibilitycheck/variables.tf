# Variables for PlausibilityCheck Terraform Module

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-1"
}

variable "aws_profile" {
  description = "AWS CLI profile"
  type        = string
  default     = "AdministratorAccess-975232045453"
}

variable "project_name" {
  description = "Project name (used for resource naming)"
  type        = string
  default     = "certification"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

# Existing Infrastructure - now pulled from certification remote state
# vpc_id, private_subnet_id, webapp_sg_id, ecs_cluster_name, service_discovery_namespace
# are all referenced via terraform remote state from certification module

variable "codestar_connection_arn" {
  description = "Existing CodeStar connection ARN for GitHub"
  type        = string
  default     = "arn:aws:codeconnections:us-west-1:975232045453:connection/50237d7b-2e11-4c72-a90a-e04e5b37a18c"
}

# ECS Task Configuration
variable "task_cpu" {
  description = "CPU units for the task"
  type        = string
  default     = "512"
}

variable "task_memory" {
  description = "Memory for the task"
  type        = string
  default     = "1024"
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 1
}

# GitHub Configuration
variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "plausibilitycheck"
}

variable "github_branch" {
  description = "GitHub branch to track"
  type        = string
  default     = "main"
}

# Logging
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}
