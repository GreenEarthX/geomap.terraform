# terraform-certification-backend/variables.tf

variable "aws_region" {
  description = "The AWS region to deploy to"
  type        = string
  default     = "us-west-1"
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "cert-backend"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

# ECS Configuration
variable "api_cpu" {
  description = "CPU units for API task"
  type        = string
  default     = "512"
}

variable "api_memory" {
  description = "Memory for API task"
  type        = string
  default     = "1024"
}

variable "api_port" {
  description = "Port the API listens on"
  type        = number
  default     = 3000
}

# RDS Configuration
variable "rds_database_name" {
  description = "The name of the database"
  type        = string
  default     = "cert_backend_db"
}

variable "rds_username" {
  description = "Master username for RDS"
  type        = string
  default     = "postgres"
}

variable "rds_password" {
  description = "Master password for RDS"
  type        = string
  sensitive   = true
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "rds_allocated_storage" {
  description = "Allocated storage for RDS in GB"
  type        = number
  default     = 20
}

variable "rds_max_allocated_storage" {
  description = "Maximum allocated storage for RDS autoscaling in GB"
  type        = number
  default     = 100
}

variable "rds_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "17.2"
}

# JWT Configuration
variable "geomap_jwt_issuer" {
  description = "JWT issuer for geomap integration"
  type        = string
  default     = "onboarding-app"
}

variable "geomap_jwt_audience" {
  description = "JWT audience for geomap integration"
  type        = string
  default     = "geomap-app"
}
