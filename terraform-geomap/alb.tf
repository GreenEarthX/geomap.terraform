# terraform-geomap/alb.tf
# Target Group and Listener Rule for Shared ALB

# Target Group
resource "aws_lb_target_group" "geomap" {
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

# Listener Rule to attach geomap to shared ALB's HTTPS listener
resource "aws_lb_listener_rule" "geomap" {
  listener_arn = data.terraform_remote_state.shared.outputs.shared_alb_https_listener_arn

  condition {
    host_header {
      values = ["${var.subdomain}.${data.terraform_remote_state.shared.outputs.domain_name}"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.geomap.arn
  }

  tags = {
    Name        = "${var.app_name}-listener-rule"
    Environment = var.environment
  }
}
