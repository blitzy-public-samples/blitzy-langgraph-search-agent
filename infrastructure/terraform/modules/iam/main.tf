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

# Dynamically fetch GitHub OIDC thumbprint from the certificate chain
# This ensures the thumbprint is always current and eliminates manual updates
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

# -----------------------------------------------------------------------------
# GitHub Actions OIDC Provider
# -----------------------------------------------------------------------------
# Creates the OIDC identity provider for GitHub Actions to assume IAM roles
# without long-lived credentials.
# -----------------------------------------------------------------------------
resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  # Use dynamic thumbprint from tls_certificate data source if available,
  # otherwise fall back to the provided variable thumbprint
  thumbprint_list = [
    coalesce(
      try(data.tls_certificate.github.certificates[0].sha1_fingerprint, null),
      var.github_oidc_thumbprint
    )
  ]

  tags = local.merged_tags
}

# -----------------------------------------------------------------------------
# GitHub Actions IAM Role
# -----------------------------------------------------------------------------
# Role assumed by GitHub Actions workflows for deployment operations.
# Trust policy restricts access to specific repository.
# -----------------------------------------------------------------------------
# Local value for OIDC provider ARN - handles both created and existing providers
locals {
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
}

resource "aws_iam_role" "github_actions" {
  name                 = local.github_actions_role_name
  max_session_duration = var.role_max_session_duration
  permissions_boundary = var.permissions_boundary_arn != "" ? var.permissions_boundary_arn : null

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = local.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # Support both wildcard (*) and specific branch patterns
            "token.actions.githubusercontent.com:sub" = [
              for branch in var.allowed_github_branches :
              branch == "*" ? "repo:${var.github_org}/${var.github_repo}:*" : "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${branch}"
            ]
          }
        }
      }
    ]
  })

  tags = local.merged_tags
}

# -----------------------------------------------------------------------------
# GitHub Actions Role Policy - ECR Permissions
# Only created when ECR repository ARN is provided
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy" "github_actions_ecr" {
  count = var.ecr_repository_arn != "" ? 1 : 0

  name = "${var.project_name}-github-actions-ecr-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRAuthToken"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECRPullPush"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages"
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
    Statement = concat(
      [
        {
          Sid    = "ECSTaskDefinitionOperations"
          Effect = "Allow"
          Action = [
            "ecs:DescribeTaskDefinition",
            "ecs:RegisterTaskDefinition",
            "ecs:DeregisterTaskDefinition",
            "ecs:ListTaskDefinitions"
          ]
          Resource = "*"
        },
        {
          Sid    = "ECSServiceOperations"
          Effect = "Allow"
          Action = [
            "ecs:DescribeServices",
            "ecs:UpdateService",
            "ecs:ListServices"
          ]
          Resource = var.ecs_cluster_arn != "" ? [
            "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:service/${element(split("/", var.ecs_cluster_arn), length(split("/", var.ecs_cluster_arn)) - 1)}/*"
          ] : ["*"]
        },
        {
          Sid    = "ECSClusterOperations"
          Effect = "Allow"
          Action = [
            "ecs:DescribeClusters",
            "ecs:ListClusters"
          ]
          Resource = var.ecs_cluster_arn != "" ? [var.ecs_cluster_arn] : ["*"]
        },
        {
          Sid    = "ECSTaskOperations"
          Effect = "Allow"
          Action = [
            "ecs:DescribeTasks",
            "ecs:ListTasks",
            "ecs:RunTask",
            "ecs:StopTask"
          ]
          Resource = "*"
        }
      ],
      # Conditionally add PassRole permission based on variable
      var.enable_pass_role ? [
        {
          Sid    = "PassRoleToECS"
          Effect = "Allow"
          Action = [
            "iam:PassRole"
          ]
          Resource = [
            aws_iam_role.ecs_task_execution.arn,
            aws_iam_role.ecs_task.arn
          ]
          Condition = {
            StringEquals = {
              "iam:PassedToService" = "ecs-tasks.amazonaws.com"
            }
          }
        }
      ] : []
    )
  })
}

# -----------------------------------------------------------------------------
# GitHub Actions Role Policy - S3 Permissions
# Only created when S3 bucket ARN is provided
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy" "github_actions_s3" {
  count = var.s3_bucket_arn != "" ? 1 : 0

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
          "s3:ListBucket",
          "s3:GetObjectVersion",
          "s3:ListBucketVersions"
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
# Only created when CloudFront distribution ARN is provided
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy" "github_actions_cloudfront" {
  count = var.cloudfront_distribution_arn != "" ? 1 : 0

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
          "cloudfront:ListInvalidations",
          "cloudfront:GetDistribution"
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
  name                 = local.ecs_task_execution_role_name
  max_session_duration = var.role_max_session_duration
  permissions_boundary = var.permissions_boundary_arn != "" ? var.permissions_boundary_arn : null

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
  name                 = local.ecs_task_role_name
  max_session_duration = var.role_max_session_duration
  permissions_boundary = var.permissions_boundary_arn != "" ? var.permissions_boundary_arn : null

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
  count = var.dynamodb_table_arn != "" ? 1 : 0

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

# CloudWatch Logs access policy for the task role
# Allows the application to create and write logs directly
resource "aws_iam_role_policy" "ecs_task_cloudwatch" {
  name = "${var.project_name}-ecs-task-cloudwatch-policy"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.project_name}*",
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.project_name}*:*"
        ]
      }
    ]
  })
}
