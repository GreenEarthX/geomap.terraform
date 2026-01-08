# terraform-certification-backend/service-discovery.tf
# AWS Cloud Map Service Discovery for internal service communication

# Service Discovery Service
resource "aws_service_discovery_service" "api" {
  name = "api"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }

  tags = {
    Name        = "${var.project_name}-service-discovery"
    Environment = var.environment
  }
}

# Private DNS Namespace for service discovery
resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "${var.project_name}.local"
  description = "Service discovery namespace for certification backend"
  vpc         = data.terraform_remote_state.shared.outputs.vpc_id

  tags = {
    Name        = "${var.project_name}-namespace"
    Environment = var.environment
  }
}
