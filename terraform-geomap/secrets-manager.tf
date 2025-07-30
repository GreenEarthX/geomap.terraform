# terraform-geomap/secrets-manager.tf
# Secrets Manager for Application Secrets
resource "aws_secretsmanager_secret" "geomap_app_secrets" {
  name        = "${var.app_name}-app-secrets"
  description = "Application secrets for ${var.app_name} app"

  tags = {
    Name        = "${var.app_name}-app-secrets"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "geomap_app_secrets" {
  secret_id = aws_secretsmanager_secret.geomap_app_secrets.id
  secret_string = jsonencode({
    DATABASE_URL     = "postgresql://postgres:${var.db_password}@${aws_db_instance.geomap.endpoint}/${var.db_name}"
    JWT_SECRET      = var.jwt_secret
    NEXTAUTH_SECRET = var.nextauth_secret
    # Domain-related env vars commented out for testing
    # NEXTAUTH_URL    = "https://${var.subdomain}.${data.terraform_remote_state.shared.outputs.domain_name}"
  })

  depends_on = [aws_db_instance.geomap]
}
