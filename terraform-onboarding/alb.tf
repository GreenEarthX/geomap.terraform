# terraform-onboarding/alb.tf
# Application Load Balancer configuration - using shared ALB

# Target Group
resource "aws_lb_target_group" "onboarding" {
  name        = "${var.app_name}-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.shared.outputs.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/api/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "${var.app_name}-target-group"
    Environment = var.environment
  }
}

# Listener Rule for host-based routing on shared ALB
resource "aws_lb_listener_rule" "onboarding" {
  listener_arn = data.terraform_remote_state.shared.outputs.shared_alb_https_listener_arn
  priority     = 200  # Different priority from geomap (which uses default/auto)

  condition {
    host_header {
      values = ["${var.subdomain}.${data.terraform_remote_state.shared.outputs.domain_name}"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.onboarding.arn
  }

  tags = {
    Name        = "${var.app_name}-listener-rule"
    Environment = var.environment
  }
}