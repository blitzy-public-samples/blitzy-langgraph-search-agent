# -----------------------------------------------------------------------------
# IAM Module - Input Variables
# LangGraph Search Agent Infrastructure
# -----------------------------------------------------------------------------
# This file defines all input variables for the IAM module, which creates:
# - ECS Task Execution Role (for ECR pull, CloudWatch logs, Secrets Manager)
# - ECS Task Role (for container runtime permissions like DynamoDB access)
# - GitHub Actions OIDC Provider and Role (for CI/CD authentication)
#
# Variable categories:
# 1. Project identification
# 2. GitHub OIDC configuration
# 3. ECR configuration
# 4. S3/CloudFront configuration
# 5. ECS configuration
# 6. DynamoDB configuration
# 7. Secrets Manager configuration
# 8. CloudWatch configuration
# 9. Resource tagging
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# 1. Project Identification Variables
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Name of the project, used for resource naming. Must match existing CI/CD workflow expectations."
  type        = string
  default     = "langgraph-search-agent"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must only contain lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod). Used for resource tagging and naming."
  type        = string
  default     = "production"

  validation {
    condition     = contains(["dev", "staging", "prod", "production", "development"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, production, development."
  }
}

variable "aws_region" {
  description = "AWS region for resource deployment. All resources must be in us-east-1 per project constraints."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = var.aws_region == "us-east-1"
    error_message = "AWS region must be us-east-1 per project constraints (Constraint C-005)."
  }
}

# -----------------------------------------------------------------------------
# 2. GitHub OIDC Configuration Variables
# These variables configure the GitHub Actions OIDC provider for secure
# authentication without long-lived AWS credentials.
# -----------------------------------------------------------------------------

variable "github_org" {
  description = "GitHub organization or username for OIDC trust policy. Used in the trust relationship condition to restrict which GitHub repos can assume the role."
  type        = string

  validation {
    condition     = length(var.github_org) > 0
    error_message = "GitHub organization/username is required for OIDC configuration."
  }
}

variable "github_repo" {
  description = "GitHub repository name for OIDC trust policy. Used in the trust relationship condition to restrict role assumption to specific repository."
  type        = string

  validation {
    condition     = length(var.github_repo) > 0
    error_message = "GitHub repository name is required for OIDC configuration."
  }
}

variable "github_oidc_thumbprint" {
  description = "GitHub OIDC provider thumbprint for SSL certificate validation. This is GitHub's intermediate certificate thumbprint."
  type        = string
  default     = "6938fd4d98bab03faadb97b34396831e3780aea1"

  validation {
    condition     = can(regex("^[a-f0-9]{40}$", var.github_oidc_thumbprint))
    error_message = "GitHub OIDC thumbprint must be a 40-character lowercase hexadecimal string."
  }
}

variable "allowed_github_branches" {
  description = "List of GitHub branches that are allowed to assume the OIDC role. Use '*' for all branches. Defaults to main branch only for security."
  type        = list(string)
  default     = ["main"]
}

variable "create_oidc_provider" {
  description = "Whether to create the GitHub OIDC provider. Set to false if it already exists in your AWS account to avoid resource conflict."
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# 3. ECR Configuration Variables
# Permissions for pushing and pulling container images to/from ECR.
# Required for backend deployment workflow.
# -----------------------------------------------------------------------------

variable "ecr_repository_arn" {
  description = "ARN of the ECR repository for push/pull permissions. Required for GitHub Actions to push Docker images. Format: arn:aws:ecr:region:account-id:repository/repo-name"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:ecr:[a-z0-9-]+:[0-9]+:repository/.+$", var.ecr_repository_arn)) || var.ecr_repository_arn == ""
    error_message = "ECR repository ARN must be a valid ARN format or empty string."
  }
}

# -----------------------------------------------------------------------------
# 4. S3/CloudFront Configuration Variables
# Permissions for frontend deployment - S3 sync and CloudFront invalidation.
# -----------------------------------------------------------------------------

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket for frontend deployment permissions. Used for syncing static assets. Leave empty if frontend module not deployed."
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^arn:aws:s3:::.+$", var.s3_bucket_arn)) || var.s3_bucket_arn == ""
    error_message = "S3 bucket ARN must be a valid ARN format or empty string."
  }
}

variable "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution for invalidation permissions. Used after S3 sync to clear CDN cache. Leave empty if frontend module not deployed."
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^arn:aws:cloudfront::[0-9]+:distribution/.+$", var.cloudfront_distribution_arn)) || var.cloudfront_distribution_arn == ""
    error_message = "CloudFront distribution ARN must be a valid ARN format or empty string."
  }
}

# -----------------------------------------------------------------------------
# 5. ECS Configuration Variables
# Permissions for ECS deployment - service updates and task definitions.
# -----------------------------------------------------------------------------

variable "ecs_cluster_arn" {
  description = "ARN of the ECS cluster for deployment permissions. Required for GitHub Actions to deploy task definitions and update services."
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^arn:aws:ecs:[a-z0-9-]+:[0-9]+:cluster/.+$", var.ecs_cluster_arn)) || var.ecs_cluster_arn == ""
    error_message = "ECS cluster ARN must be a valid ARN format or empty string."
  }
}

variable "ecs_service_arn" {
  description = "ARN of the ECS service for deployment permissions. Required for GitHub Actions to update the service with new task definitions."
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^arn:aws:ecs:[a-z0-9-]+:[0-9]+:service/.+/.+$", var.ecs_service_arn)) || var.ecs_service_arn == ""
    error_message = "ECS service ARN must be a valid ARN format or empty string."
  }
}

variable "ecs_task_definition_arn_prefix" {
  description = "ARN prefix for ECS task definitions. Used to grant permissions to register and describe task definitions. Format: arn:aws:ecs:region:account-id:task-definition/family"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# 6. DynamoDB Configuration Variables
# Permissions for application runtime access to DynamoDB.
# Used by ECS Task Role for future session persistence.
# -----------------------------------------------------------------------------

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table for task role permissions. Grants read/write access to the langgraph-conversations table for session persistence."
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^arn:aws:dynamodb:[a-z0-9-]+:[0-9]+:table/.+$", var.dynamodb_table_arn)) || var.dynamodb_table_arn == ""
    error_message = "DynamoDB table ARN must be a valid ARN format or empty string."
  }
}

# -----------------------------------------------------------------------------
# 7. Secrets Manager Configuration Variables
# Permissions for ECS Task Execution Role to read secrets at container startup.
# Used for API keys (OPENAI_API_KEY, TAVILY_API_KEY).
# -----------------------------------------------------------------------------

variable "secrets_arns" {
  description = "List of Secrets Manager secret ARNs for task execution role. Grants GetSecretValue permission for injecting secrets into ECS task environment."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for arn in var.secrets_arns :
      can(regex("^arn:aws:secretsmanager:[a-z0-9-]+:[0-9]+:secret:.+$", arn))
    ])
    error_message = "All secrets ARNs must be valid Secrets Manager ARN format."
  }
}

# -----------------------------------------------------------------------------
# 8. CloudWatch Configuration Variables
# Permissions for ECS Task Execution Role to write container logs.
# -----------------------------------------------------------------------------

variable "log_group_arn" {
  description = "ARN of the CloudWatch log group for ECS task logging. Grants CreateLogStream and PutLogEvents permissions."
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^arn:aws:logs:[a-z0-9-]+:[0-9]+:log-group:.+$", var.log_group_arn)) || var.log_group_arn == ""
    error_message = "CloudWatch log group ARN must be a valid ARN format or empty string."
  }
}

variable "log_group_name" {
  description = "Name of the CloudWatch log group (without ARN). Alternative to log_group_arn for simpler configuration."
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# 9. Resource Tagging Variables
# Consistent tagging applied to all IAM resources for cost tracking,
# compliance, and resource organization.
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Tags to apply to all IAM resources. Should include Project, Environment, ManagedBy, and Region tags per project standards."
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# 10. Advanced Configuration Variables
# Optional settings for fine-grained control over IAM resources.
# -----------------------------------------------------------------------------

variable "task_execution_role_name" {
  description = "Custom name for the ECS task execution role. If not specified, defaults to {project_name}-task-execution-role."
  type        = string
  default     = ""
}

variable "task_role_name" {
  description = "Custom name for the ECS task role. If not specified, defaults to {project_name}-task-role."
  type        = string
  default     = ""
}

variable "github_actions_role_name" {
  description = "Custom name for the GitHub Actions OIDC role. If not specified, defaults to {project_name}-github-actions-role."
  type        = string
  default     = ""
}

variable "permissions_boundary_arn" {
  description = "ARN of the IAM permissions boundary to attach to all roles. Leave empty for no boundary."
  type        = string
  default     = ""
}

variable "role_max_session_duration" {
  description = "Maximum session duration in seconds for IAM roles. Must be between 3600 (1 hour) and 43200 (12 hours)."
  type        = number
  default     = 3600

  validation {
    condition     = var.role_max_session_duration >= 3600 && var.role_max_session_duration <= 43200
    error_message = "Role max session duration must be between 3600 and 43200 seconds."
  }
}

variable "enable_pass_role" {
  description = "Whether to grant iam:PassRole permission to GitHub Actions role for ECS task definition registration."
  type        = bool
  default     = true
}
