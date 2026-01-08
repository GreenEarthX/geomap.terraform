# Fix for OcrPlausibilityCheck CodePipeline ECS Deployment Error

## Problem
The CodePipeline deployment stage was failing with:
```
The provided role does not have sufficient permissions to access ECS
```

## Root Cause
The **CodePipeline IAM role** (`gex-ocr-plausibility-pipeline-role`) was missing critical ECS and IAM permissions needed for the ECS deployment provider.

Specifically, the IAM PassRole permission was too broad (`Resource = "*"`) and missing the specific role ARNs, plus some ECS actions were missing.

## Solution Applied

### Updated CodePipeline IAM Policy
**File**: `/Users/medbnk/GEX/infrastructure/terraform-OcrPlausibilityCheck/main.tf`

**Changes Made**:

1. **Added Missing ECS Actions**:
   - `ecs:DescribeClusters` ✅
   - `ecs:ListTaskDefinitions` ✅
   - `ecs:DeregisterTaskDefinition` ✅

2. **Fixed IAM PassRole Permission**:
   - Changed from `Resource = "*"` (too permissive and potentially blocked)
   - To specific resources:
     ```terraform
     Resource = [
       aws_iam_role.ecs_task_execution.arn,
       aws_iam_role.ecs_task.arn
     ]
     ```

### Updated Policy (Lines 481-540)
```terraform
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
          "ecs:DescribeClusters",           # ADDED
          "ecs:ListTaskDefinitions",        # ADDED
          "ecs:DeregisterTaskDefinition"    # ADDED
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = ["iam:PassRole"]
        Resource = [
          aws_iam_role.ecs_task_execution.arn,  # FIXED - specific ARNs
          aws_iam_role.ecs_task.arn              # FIXED - specific ARNs
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
```

## Deployment Steps

### 1. Refresh AWS Credentials
```bash
aws sso login --profile AdministratorAccess-975232045453
```

### 2. Apply Terraform Changes
```bash
cd /Users/medbnk/GEX/infrastructure/terraform-OcrPlausibilityCheck

# Plan the changes
terraform plan -out=tfplan

# Review the plan - should show:
# - aws_iam_role_policy.codepipeline will be updated in-place

# Apply the changes
terraform apply tfplan
```

### 3. Test the Pipeline
```bash
# Trigger the pipeline manually
aws codepipeline start-pipeline-execution \
  --name gex-ocr-plausibility-pipeline \
  --region us-west-1 \
  --profile AdministratorAccess-975232045453

# Or push a commit to trigger automatically
cd /Users/medbnk/GEX/OcrPlausibilityCheck
git add .
git commit -m "Test pipeline deployment"
git push origin main
```

### 4. Monitor Deployment
```bash
# Watch pipeline execution
aws codepipeline get-pipeline-state \
  --name gex-ocr-plausibility-pipeline \
  --region us-west-1 \
  --profile AdministratorAccess-975232045453

# Check ECS service status
aws ecs describe-services \
  --cluster certification-cluster \
  --services gex-ocr-plausibility \
  --region us-west-1 \
  --profile AdministratorAccess-975232045453
```

## What Was Wrong vs What's Fixed

### Before ❌
```terraform
{
  Effect = "Allow"
  Action = ["iam:PassRole"]
  Resource = "*"  # Too broad, potentially blocked by SCPs
  Condition = {
    StringEqualsIfExists = {
      "iam:PassedToService" = ["ecs-tasks.amazonaws.com"]
    }
  }
}
```

### After ✅
```terraform
{
  Effect = "Allow"
  Action = ["iam:PassRole"]
  Resource = [
    aws_iam_role.ecs_task_execution.arn,  # Specific role ARN
    aws_iam_role.ecs_task.arn              # Specific role ARN
  ]
  Condition = {
    StringEqualsIfExists = {
      "iam:PassedToService" = ["ecs-tasks.amazonaws.com"]
    }
  }
}
```

## Resource Names Reference

Based on your Terraform configuration:

| Resource Type | Name/ARN |
|--------------|----------|
| **CodePipeline** | `gex-ocr-plausibility-pipeline` |
| **CodePipeline Role** | `gex-ocr-plausibility-pipeline-role` |
| **CodeBuild Project** | `gex-ocr-plausibility-build` |
| **ECS Cluster** | `certification-cluster` (from remote state) |
| **ECS Service** | `gex-ocr-plausibility` |
| **ECS Task Definition** | `gex-ocr-plausibility` |
| **ECR Repository** | `gex-ocr-plausibility` |
| **Container Name** | `gex-ocr-plausibility` |
| **ECS Task Execution Role** | `gex-ocr-plausibility-task-exec-role` |
| **ECS Task Role** | `gex-ocr-plausibility-task-role` |

## Verification Checklist

After applying Terraform changes:

- [ ] Terraform apply completed successfully
- [ ] IAM role policy updated in AWS Console
- [ ] CodePipeline execution triggered
- [ ] Source stage: ✅ Success
- [ ] Build stage: ✅ Success (was already working)
- [ ] Deploy stage: ✅ Success (should now work)
- [ ] ECS service updated with new task definition
- [ ] Container running and healthy

## Troubleshooting

If the deployment still fails:

### Check IAM Role Trust Relationship
```bash
aws iam get-role \
  --role-name gex-ocr-plausibility-pipeline-role \
  --region us-west-1 \
  --profile AdministratorAccess-975232045453
```

### Check Pipeline Execution Details
```bash
aws codepipeline get-pipeline-execution \
  --pipeline-name gex-ocr-plausibility-pipeline \
  --pipeline-execution-id <execution-id> \
  --region us-west-1 \
  --profile AdministratorAccess-975232045453
```

### Check ECS Service Events
```bash
aws ecs describe-services \
  --cluster certification-cluster \
  --services gex-ocr-plausibility \
  --region us-west-1 \
  --profile AdministratorAccess-975232045453 \
  | jq '.services[0].events'
```

### Verify buildspec.yml Creates imagedefinitions.json
The Deploy stage expects `imagedefinitions.json` in the build output. Verify your buildspec.yml has:

```yaml
artifacts:
  files:
    - imagedefinitions.json
```

And the file is created with:
```json
[
  {
    "name": "gex-ocr-plausibility",
    "imageUri": "<ECR_REPOSITORY_URI>:latest"
  }
]
```

## Summary

**The fix**: Updated the CodePipeline IAM role policy to include specific ECS task role ARNs for PassRole permission and added missing ECS actions.

**Impact**: CodePipeline's Deploy stage should now successfully deploy to ECS without permission errors.

**Next Step**: Apply Terraform changes and test the pipeline! 🚀
