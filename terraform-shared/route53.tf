# terraform-shared/route53.tf
# Route53 configuration commented out for testing - using ALB DNS instead
# # Route 53 DNS Configuration
# data "aws_route53_zone" "main" {
#   name         = var.domain_name
#   private_zone = false
# }

# # Export the zone information for use by apps
# output "route53_zone_id" {
#   description = "Route53 zone ID"
#   value       = data.aws_route53_zone.main.zone_id
# }

# output "route53_zone_name" {
#   description = "Route53 zone name"
#   value       = data.aws_route53_zone.main.name
# }
