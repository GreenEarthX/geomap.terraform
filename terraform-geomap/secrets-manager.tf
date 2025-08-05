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
    DATABASE_URL                = "postgresql://postgres:${var.db_password}@${aws_db_instance.geomap.endpoint}/${var.db_name}"
    GEOMAP_JWT_SECRET          = var.geomap_jwt_secret
    ONBOARDING_APP_URL         = var.onboarding_app_url
    NEXT_PUBLIC_ONBOARDING_URL = var.next_public_onboarding_url
    GEOMAP_URL                 = "http://${aws_lb.geomap.dns_name}"
    NEXT_PUBLIC_GEOMAP_URL     = "http://${aws_lb.geomap.dns_name}"
    NEXTAUTH_URL               = "http://${aws_lb.geomap.dns_name}"
  })

  depends_on = [aws_db_instance.geomap, aws_lb.geomap]
}
