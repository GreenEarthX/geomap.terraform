# terraform-onboarding/secrets-manager.tf
# Secrets Manager for Application Secrets
resource "aws_secretsmanager_secret" "onboarding_app_secrets" {
  name        = "${var.app_name}-app-secrets"
  description = "Application secrets for ${var.app_name} app"

  tags = {
    Name        = "${var.app_name}-app-secrets"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "onboarding_app_secrets" {
  secret_id = aws_secretsmanager_secret.onboarding_app_secrets.id
  secret_string = jsonencode({
    DATABASE_URL              = "postgresql://postgres:${var.db_password}@${aws_db_instance.onboarding.endpoint}/${var.db_name}"
    NEXTAUTH_URL             = "http://${aws_lb.onboarding.dns_name}"
    NEXTAUTH_SECRET          = var.nextauth_secret
    NEXT_PUBLIC_APP_URL      = "http://${aws_lb.onboarding.dns_name}"
    JWT_SECRET               = var.jwt_secret
    GOOGLE_CLIENT_ID         = var.google_client_id
    GOOGLE_CLIENT_SECRET     = var.google_client_secret
    EMAIL_USER               = var.email_user
    EMAIL_PASS               = var.email_pass
    NEXT_PUBLIC_RECAPTCHA_SITE_KEY = var.recaptcha_site_key
    RECAPTCHA_SECRET_KEY     = var.recaptcha_secret_key
    GEOMAP_URL              = var.geomap_url
    NEXT_PUBLIC_GEOMAP_URL  = var.geomap_url
    GEOMAP_JWT_SECRET       = var.geomap_jwt_secret
    GEOMAP_APP_URL          = var.geomap_app_url
  })

  depends_on = [aws_db_instance.onboarding]
}
