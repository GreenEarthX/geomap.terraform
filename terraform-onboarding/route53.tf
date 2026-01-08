# terraform-onboarding/route53.tf
# Route53 DNS configuration - pointing to shared ALB

# DNS Record for Application (using shared ALB)
resource "aws_route53_record" "onboarding" {
  zone_id = data.terraform_remote_state.shared.outputs.route53_zone_id
  name    = "${var.subdomain}.${data.terraform_remote_state.shared.outputs.domain_name}"
  type    = "A"

  alias {
    name                   = data.terraform_remote_state.shared.outputs.shared_alb_dns_name
    zone_id                = data.terraform_remote_state.shared.outputs.shared_alb_zone_id
    evaluate_target_health = true
  }
}
