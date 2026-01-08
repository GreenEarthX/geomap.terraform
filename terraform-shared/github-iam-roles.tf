# GitHub Actions IAM Role
# Allows GitHub Actions from specified repositories to assume this role

locals {
  # GitHub organization - update this to your actual GitHub organization/username
  github_org = "GreenEarthX"

  # All repositories that can assume this role
  # Using wildcards to allow any repo in the org with these prefixes
  allowed_repos = [
    "repo:${local.github_org}/geomap*:*",
    "repo:${local.github_org}/onboarding*:*",
    "repo:${local.github_org}/certification*:*",
    "repo:${local.github_org}/OcrPlausibilityCheck:*",
    "repo:${local.github_org}/PlausibilityCheck:*",
    "repo:${local.github_org}/Certif2_backend:*",
    "repo:${local.github_org}/*:*"  # Allow all repos in org if needed
  ]
}

resource "aws_iam_role" "github_actions" {
  name        = "github-actions-deploy-role"
  description = "Role for GitHub Actions to deploy to ECS/ECR"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = local.allowed_repos
          }
        }
      }
    ]
  })

  tags = {
    Name        = "github-actions-deploy-role"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Attach the deployment policy to the role
resource "aws_iam_role_policy_attachment" "github_actions_deploy" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_deploy.arn
}
