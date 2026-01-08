# terraform-certification-backend/security-groups.tf
# Security Groups for API and RDS

# Reference the certification webapp terraform state
data "terraform_remote_state" "certification" {
  backend = "s3"
  config = {
    bucket  = "terraform-geomap-state"
    key     = "certification/terraform.tfstate"
    region  = var.aws_region
    profile = "AdministratorAccess-975232045453"
  }
}

# Security Group for API
resource "aws_security_group" "api" {
  name        = "${var.project_name}-api-sg"
  description = "Security group for certification backend API"
  vpc_id      = data.terraform_remote_state.shared.outputs.vpc_id

  # Allow traffic from the certification webapp (frontend)
  ingress {
    from_port       = var.api_port
    to_port         = var.api_port
    protocol        = "tcp"
    security_groups = [data.terraform_remote_state.certification.outputs.webapp_security_group_id]
    description     = "Allow traffic from certification webapp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-api-sg"
    Environment = var.environment
  }
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = data.terraform_remote_state.shared.outputs.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.api.id]
    description     = "Allow PostgreSQL from API"
  }

  # Allow from bastion host for database management
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [data.terraform_remote_state.shared.outputs.bastion_security_group_id]
    description     = "Allow PostgreSQL from bastion host"
  }

  # Allow from shared ECS security group (for onboarding service)
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [data.terraform_remote_state.shared.outputs.ecs_security_group_id]
    description     = "Allow PostgreSQL from shared ECS (onboarding)"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-rds-sg"
    Environment = var.environment
  }
}
