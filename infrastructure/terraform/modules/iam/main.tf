# -----------------------------------------------------------------------------
# IAM Module - Main Configuration
# -----------------------------------------------------------------------------
# Creates IAM roles and policies for:
# 1. GitHub Actions OIDC Provider - Enables passwordless authentication
# 2. GitHub Actions Role - Permissions for CI/CD workflows
# 3. ECS Task Execution Role - Permissions for task startup (ECR pull, logs)
# 4. ECS Task Role - Container runtime permissions (DynamoDB, etc.)
# -----------------------------------------------------------------------------

locals {
  default_tags = {
    Module = "iam"
  }
  merged_tags = merge(local.default_tags, var.tags)

  github_actions_role_name     = "${var.project_name}-github-actions-role"
  ecs_task_execution_role_name = "${var.project_name}-ecs-task-execution-role"
  ecs_task_role_name           = "${var.project_name}-ecs-task-role"
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# GitHub Actions OIDC Provider
# -----------------------------------------------------------------------------
# Creates the OIDC identity provider for GitHub Actions to assume IAM roles
# without long-lived credentials.
# -----------------------------------------------------------------------------
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [var.github_oidc_thumbprint]

  tags = local.merged_tags
}

# -----------------------------------------------------------------------------
# GitHub Actions IAM Role
# -----------------------------------------------------------------------------
# Role assumed by GitHub Actions workflows for deployment operations.
# Trust policy restricts access to specific repository.
# -----------------------------------------------------------------------------
resource "aws_iam_role" "github_actions" {
  name = local.github_actions_role_name

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
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
          }
        }
      }
    ]
  })

  tags = local.merged_tags
}

# -----------------------------------------------------------------------------
# GitHub Actions Role Policy - ECR Permissions
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy" "github_actions_ecr" {
  name = "${var.project_name}-github-actions-ecr-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = var.ecr_repository_arn
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# GitHub Actions Role Policy - ECS Permissions
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy" "github_actions_ecs" {
  name = "${var.project_name}-github-actions-ecs-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeTasks",
          "ecs:ListTasks",
          "ecs:RegisterTaskDefinition",
          "ecs:UpdateService"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          aws_iam_role.ecs_task_execution.arn,
          aws_iam_role.ecs_task.arn
        ]
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# GitHub Actions Role Policy - S3 Permissions
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy" "github_actions_s3" {
  name = "${var.project_name}-github-actions-s3-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# GitHub Actions Role Policy - CloudFront Permissions
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy" "github_actions_cloudfront" {
  name = "${var.project_name}-github-actions-cloudfront-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation",
          "cloudfront:GetInvalidation",
          "cloudfront:ListInvalidations"
        ]
        Resource = var.cloudfront_distribution_arn
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# ECS Task Execution Role
# -----------------------------------------------------------------------------
# Role used by ECS to start tasks. Grants permissions to pull images from ECR,
# write logs to CloudWatch, and read secrets from Secrets Manager.
# -----------------------------------------------------------------------------
resource "aws_iam_role" "ecs_task_execution" {
  name = local.ecs_task_execution_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.merged_tags
}

# Attach AWS managed policy for basic ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution_basic" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Additional policy for Secrets Manager access
resource "aws_iam_role_policy" "ecs_task_execution_secrets" {
  count = length(var.secrets_arns) > 0 ? 1 : 0

  name = "${var.project_name}-ecs-task-execution-secrets-policy"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.secrets_arns
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# ECS Task Role
# -----------------------------------------------------------------------------
# Role used by the running container. Grants permissions needed by the
# application at runtime (e.g., DynamoDB access).
# -----------------------------------------------------------------------------
resource "aws_iam_role" "ecs_task" {
  name = local.ecs_task_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.merged_tags
}

# DynamoDB access policy for the task role
resource "aws_iam_role_policy" "ecs_task_dynamodb" {
  name = "${var.project_name}-ecs-task-dynamodb-policy"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:DeleteItem",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem"
        ]
        Resource = [
          var.dynamodb_table_arn,
          "${var.dynamodb_table_arn}/index/*"
        ]
      }
    ]
  })
}
