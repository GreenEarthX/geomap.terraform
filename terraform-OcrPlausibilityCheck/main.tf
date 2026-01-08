# Terraform configuration for OcrPlausibilityCheck FastAPI Service
# This service runs on port 8000 in a private subnet

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "terraform-geomap-state"
    key     = "ocr-plausibility/terraform.tfstate"
    region  = "us-west-1"
    profile = "AdministratorAccess-975232045453"
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# Reference certification infrastructure
data "terraform_remote_state" "certification" {
  backend = "s3"
  config = {
    bucket  = "terraform-geomap-state"
    key     = "certification/terraform.tfstate"
    region  = var.aws_region
    profile = var.aws_profile
  }
}

data "aws_caller_identity" "current" {}

# Data sources for certification resources via remote state
data "aws_vpc" "existing" {
  id = data.terraform_remote_state.certification.outputs.vpc_id
}

data "aws_subnet" "private_app" {
  id = data.terraform_remote_state.certification.outputs.private_subnet_id
}

data "aws_security_group" "webapp" {
  id = data.terraform_remote_state.certification.outputs.webapp_security_group_id
}

data "aws_ecs_cluster" "existing" {
  cluster_name = data.terraform_remote_state.certification.outputs.ecs_cluster_name
}

data "aws_service_discovery_dns_namespace" "existing" {
  name = data.terraform_remote_state.certification.outputs.service_discovery_namespace_name
  type = "DNS_PRIVATE"
}

# Security Group for OcrPlausibilityCheck
resource "aws_security_group" "ocr_plausibility" {
  name        = "${var.project_name}-ocr-plausibility-sg"
  description = "Security group for OcrPlausibilityCheck service on port 8000"
  vpc_id      = data.terraform_remote_state.certification.outputs.vpc_id

  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [data.terraform_remote_state.certification.outputs.webapp_security_group_id]
    description     = "Allow access from webapp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${var.project_name}-ocr-plausibility-sg"
    Environment = var.environment
    Service     = "ocr-plausibility"
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ocr_plausibility" {
  name              = "/ecs/${var.project_name}-ocr-plausibility"
  retention_in_days = var.log_retention_days

  tags = {
    Environment = var.environment
    Service     = "ocr-plausibility"
  }
}

# ECR Repository
resource "aws_ecr_repository" "ocr_plausibility" {
  name                 = "${var.project_name}-ocr-plausibility"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = var.environment
    Service     = "ocr-plausibility"
  }
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_name}-ocr-plausibility-task-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Service     = "ocr-plausibility"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Role for ECS Task
resource "aws_iam_role" "ecs_task" {
  name = "${var.project_name}-ocr-plausibility-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Service     = "ocr-plausibility"
  }
}

# Service Discovery
resource "aws_service_discovery_service" "ocr_plausibility" {
  name = "ocr-plausibility"

  dns_config {
    namespace_id = data.aws_service_discovery_dns_namespace.existing.id

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
    Environment = var.environment
    Service     = "ocr-plausibility"
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "ocr_plausibility" {
  family                   = "${var.project_name}-ocr-plausibility"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "${var.project_name}-ocr-plausibility"
      image     = "${aws_ecr_repository.ocr_plausibility.repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = 8000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "LLM_API_KEY"
          value = var.llm_api_key
        },
        {
          name  = "LLM_API_URL"
          value = var.llm_api_url
        },
        {
          name  = "LLM_MODEL"
          value = var.llm_model
        },
        {
          name  = "USE_LLM_REFINEMENT"
          value = var.use_llm_refinement
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ocr_plausibility.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Environment = var.environment
    Service     = "ocr-plausibility"
  }
}

# ECS Service
resource "aws_ecs_service" "ocr_plausibility" {
  name            = "${var.project_name}-ocr-plausibility"
  cluster         = data.aws_ecs_cluster.existing.id
  task_definition = aws_ecs_task_definition.ocr_plausibility.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [data.terraform_remote_state.certification.outputs.private_subnet_id]
    security_groups  = [aws_security_group.ocr_plausibility.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.ocr_plausibility.arn
  }

  lifecycle {
    ignore_changes = [desired_count, task_definition]
  }

  tags = {
    Environment = var.environment
    Service     = "ocr-plausibility"
  }
}

# IAM Role for CodeBuild
resource "aws_iam_role" "codebuild" {
  name = "${var.project_name}-ocr-plausibility-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Service     = "ocr-plausibility"
  }
}

resource "aws_iam_role_policy" "codebuild" {
  name = "${var.project_name}-ocr-plausibility-codebuild-policy"
  role = aws_iam_role.codebuild.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.pipeline_artifacts.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeTasks",
          "ecs:ListTasks",
          "ecs:RegisterTaskDefinition",
          "ecs:UpdateService",
          "ecs:DescribeClusters"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = ["iam:PassRole"]
        Resource = [
          aws_iam_role.ecs_task_execution.arn,
          aws_iam_role.ecs_task.arn
        ]
        Condition = {
          StringEqualsIfExists = {
            "iam:PassedToService" = ["ecs-tasks.amazonaws.com"]
          }
        }
      }
    ]
  })
}

# S3 Bucket for Pipeline Artifacts
resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket = "${var.project_name}-ocr-plausibility-pipeline-${data.aws_caller_identity.current.account_id}"

  tags = {
    Environment = var.environment
    Service     = "ocr-plausibility"
  }
}

resource "aws_s3_bucket_public_access_block" "pipeline_artifacts" {
  bucket = aws_s3_bucket.pipeline_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CodeBuild Project
resource "aws_codebuild_project" "ocr_plausibility" {
  name          = "${var.project_name}-ocr-plausibility-build"
  description   = "Builds OcrPlausibilityCheck Docker image"
  service_role  = aws_iam_role.codebuild.arn
  build_timeout = 60

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "AWS_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "PROJECT_NAME"
      value = var.project_name
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }

    environment_variable {
      name  = "ECR_REPOSITORY_URI"
      value = aws_ecr_repository.ocr_plausibility.repository_url
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/codebuild/${var.project_name}-ocr-plausibility"
      stream_name = "build"
    }
  }

  tags = {
    Environment = var.environment
    Service     = "ocr-plausibility"
  }
}

# IAM Role for CodePipeline
resource "aws_iam_role" "codepipeline" {
  name = "${var.project_name}-ocr-plausibility-pipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Service     = "ocr-plausibility"
  }
}

resource "aws_iam_role_policy" "codepipeline" {
  name = "${var.project_name}-ocr-plausibility-pipeline-policy"
  role = aws_iam_role.codepipeline.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.pipeline_artifacts.arn,
          "${aws_s3_bucket.pipeline_artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = aws_codebuild_project.ocr_plausibility.arn
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeTasks",
          "ecs:ListTasks",
          "ecs:RegisterTaskDefinition",
          "ecs:UpdateService",
          "ecs:DescribeClusters",
          "ecs:ListTaskDefinitions",
          "ecs:DeregisterTaskDefinition"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = ["iam:PassRole"]
        Resource = [
          aws_iam_role.ecs_task_execution.arn,
          aws_iam_role.ecs_task.arn
        ]
        Condition = {
          StringEqualsIfExists = {
            "iam:PassedToService" = [
              "ecs-tasks.amazonaws.com"
            ]
          }
        }
      },
      {
        Effect = "Allow"
        Action = ["codestar-connections:UseConnection"]
        Resource = var.codestar_connection_arn
      }
    ]
  })
}

# CodePipeline
resource "aws_codepipeline" "ocr_plausibility" {
  name     = "${var.project_name}-ocr-plausibility-pipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.pipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = var.codestar_connection_arn
        FullRepositoryId = "${var.github_owner}/${var.github_repo}"
        BranchName       = var.github_branch
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.ocr_plausibility.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ClusterName = data.aws_ecs_cluster.existing.cluster_name
        ServiceName = aws_ecs_service.ocr_plausibility.name
        FileName    = "imagedefinitions.json"
      }
    }
  }

  tags = {
    Environment = var.environment
    Service     = "ocr-plausibility"
  }
}
