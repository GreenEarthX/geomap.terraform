# terraform-onboarding/ecs.tf
# ECS Cluster
resource "aws_ecs_cluster" "onboarding" {
  name = "${var.app_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.app_name}-cluster"
    Environment = var.environment
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "onboarding" {
  family                   = "${var.app_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu
  memory                   = var.ecs_task_memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "${var.app_name}-app"
      image = "${aws_ecr_repository.onboarding.repository_url}:latest"
      
      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "NODE_ENV"
          value = "production"
        },
        {
          name  = "PORT"
          value = "3000"
        }
      ]

      secrets = [
        {
          name      = "DATABASE_URL"
          valueFrom = "${aws_secretsmanager_secret.onboarding_app_secrets.arn}:DATABASE_URL::"
        },
        {
          name      = "JWT_SECRET"
          valueFrom = "${aws_secretsmanager_secret.onboarding_app_secrets.arn}:JWT_SECRET::"
        },
        {
          name      = "NEXTAUTH_SECRET"
          valueFrom = "${aws_secretsmanager_secret.onboarding_app_secrets.arn}:NEXTAUTH_SECRET::"
        },
        {
          name      = "NEXTAUTH_URL"
          valueFrom = "${aws_secretsmanager_secret.onboarding_app_secrets.arn}:NEXTAUTH_URL::"
        },
        {
          name      = "GOOGLE_CLIENT_ID"
          valueFrom = "${aws_secretsmanager_secret.onboarding_app_secrets.arn}:GOOGLE_CLIENT_ID::"
        },
        {
          name      = "GOOGLE_CLIENT_SECRET"
          valueFrom = "${aws_secretsmanager_secret.onboarding_app_secrets.arn}:GOOGLE_CLIENT_SECRET::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.app_name}"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }

      essential = true
    }
  ])

  tags = {
    Name        = "${var.app_name}-task-definition"
    Environment = var.environment
  }
}

# ECS Service
resource "aws_ecs_service" "onboarding" {
  name            = "${var.app_name}-service"
  cluster         = aws_ecs_cluster.onboarding.id
  task_definition = aws_ecs_task_definition.onboarding.arn
  desired_count   = var.app_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [data.terraform_remote_state.shared.outputs.ecs_security_group_id]
    subnets          = data.terraform_remote_state.shared.outputs.private_subnet_ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.onboarding.arn
    container_name   = "${var.app_name}-app"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.onboarding_http]

  tags = {
    Name        = "${var.app_name}-service"
    Environment = var.environment
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "onboarding" {
  name              = "/ecs/${var.app_name}"
  retention_in_days = 30

  tags = {
    Name        = "${var.app_name}-logs"
    Environment = var.environment
  }
}
