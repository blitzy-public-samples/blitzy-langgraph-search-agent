# -----------------------------------------------------------------------------
# IAM Module - Output Declarations
# LangGraph Search Agent Infrastructure
# -----------------------------------------------------------------------------
# This file exports IAM role ARNs and names for use by other modules and
# CI/CD workflows. These outputs are consumed by:
#
# - ECS-Fargate module: task_execution_role_arn, task_role_arn
# - Root module outputs: github_actions_role_arn (for CI/CD configuration)
# - GitHub Actions workflows: github_actions_role_arn (OIDC authentication)
#
# Output categories:
# 1. GitHub Actions OIDC Provider outputs
# 2. GitHub Actions Role outputs
# 3. ECS Task Execution Role outputs
# 4. ECS Task Role outputs
#
# All ARN outputs follow HashiCorp module output conventions and include
# descriptive documentation explaining their usage.
# -----------------------------------------------------------------------------

# =============================================================================
# GITHUB ACTIONS OIDC PROVIDER OUTPUTS
# =============================================================================
# Outputs related to the GitHub Actions OIDC identity provider for
# passwordless AWS authentication from GitHub Actions workflows.
# -----------------------------------------------------------------------------

output "oidc_provider_arn" {
  description = <<-EOT
    ARN of the GitHub Actions OIDC identity provider.
    
    This is used to establish trust between GitHub Actions and AWS IAM.
    The provider enables GitHub Actions workflows to assume IAM roles
    without requiring long-lived AWS credentials.
    
    If create_oidc_provider is false, returns the standard OIDC provider
    ARN for the account (assumes provider already exists).
    
    Usage in trust policies:
      "Principal": {
        "Federated": "<this_arn>"
      }
  EOT
  value       = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
}

# Alias for backward compatibility and explicit naming
output "github_oidc_provider_arn" {
  description = <<-EOT
    ARN of the GitHub Actions OIDC provider (alias for oidc_provider_arn).
    
    This output provides an explicitly named reference to the GitHub
    OIDC provider for clarity in configurations that integrate multiple
    OIDC providers.
  EOT
  value       = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
}

# =============================================================================
# GITHUB ACTIONS ROLE OUTPUTS
# =============================================================================
# Outputs for the IAM role assumed by GitHub Actions workflows.
# This role grants permissions for CI/CD operations including:
# - ECR push/pull operations
# - ECS service deployments
# - S3 sync for frontend assets
# - CloudFront cache invalidation
# -----------------------------------------------------------------------------

output "github_actions_role_arn" {
  description = <<-EOT
    ARN of the IAM role for GitHub Actions OIDC authentication.
    
    This role is assumed by GitHub Actions workflows using OIDC
    authentication. It grants permissions for:
    - Pushing Docker images to ECR
    - Updating ECS services and task definitions
    - Syncing frontend assets to S3
    - Creating CloudFront cache invalidations
    
    Configure this ARN in GitHub repository secrets as AWS_ROLE_ARN
    for use with aws-actions/configure-aws-credentials action.
    
    Example workflow usage:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: $${{ secrets.AWS_ROLE_ARN }}
          aws-region: us-east-1
  EOT
  value       = aws_iam_role.github_actions.arn
}

output "github_actions_role_name" {
  description = <<-EOT
    Name of the IAM role for GitHub Actions.
    
    Useful for troubleshooting, CloudTrail log analysis, and
    referencing the role in AWS Console or CLI operations.
    
    Format: {project_name}-github-actions-role
  EOT
  value       = aws_iam_role.github_actions.name
}

output "github_actions_role_id" {
  description = <<-EOT
    Unique identifier (ID) of the GitHub Actions IAM role.
    
    This is the stable identifier that doesn't change even if
    the role is renamed. Useful for IAM policy conditions.
  EOT
  value       = aws_iam_role.github_actions.unique_id
}

# =============================================================================
# ECS TASK EXECUTION ROLE OUTPUTS
# =============================================================================
# Outputs for the ECS task execution role used by ECS to start tasks.
# This role grants permissions needed during task startup:
# - Pulling container images from ECR
# - Writing logs to CloudWatch
# - Reading secrets from Secrets Manager
# -----------------------------------------------------------------------------

output "task_execution_role_arn" {
  description = <<-EOT
    ARN of the ECS task execution role for pulling images and writing logs.
    
    This role is used by the ECS agent to:
    - Pull container images from ECR
    - Send container logs to CloudWatch Logs
    - Retrieve secrets from Secrets Manager for injection as environment variables
    
    Pass this ARN to the ECS-Fargate module as execution_role_arn.
    
    Reference in ECS task definition:
      "executionRoleArn": "<this_arn>"
  EOT
  value       = aws_iam_role.ecs_task_execution.arn
}

output "task_execution_role_name" {
  description = <<-EOT
    Name of the ECS task execution role.
    
    Useful for troubleshooting, CloudTrail log analysis, and
    IAM policy references.
    
    Format: {project_name}-ecs-task-execution-role
  EOT
  value       = aws_iam_role.ecs_task_execution.name
}

output "task_execution_role_id" {
  description = <<-EOT
    Unique identifier (ID) of the ECS task execution role.
    
    This is the stable identifier that doesn't change even if
    the role is renamed.
  EOT
  value       = aws_iam_role.ecs_task_execution.unique_id
}

# =============================================================================
# ECS TASK ROLE OUTPUTS
# =============================================================================
# Outputs for the ECS task role used by running containers.
# This role grants permissions needed by the application at runtime:
# - DynamoDB access for session persistence (future)
# - CloudWatch Logs for application logging
# -----------------------------------------------------------------------------

output "task_role_arn" {
  description = <<-EOT
    ARN of the ECS task role for container runtime permissions.
    
    This role is assumed by the running container and grants
    permissions needed by the application at runtime:
    - DynamoDB read/write for session persistence
    - CloudWatch Logs for application-level logging
    
    Pass this ARN to the ECS-Fargate module as task_role_arn.
    
    Reference in ECS task definition:
      "taskRoleArn": "<this_arn>"
  EOT
  value       = aws_iam_role.ecs_task.arn
}

output "task_role_name" {
  description = <<-EOT
    Name of the ECS task role.
    
    Useful for troubleshooting, CloudTrail log analysis, and
    IAM policy references.
    
    Format: {project_name}-ecs-task-role
  EOT
  value       = aws_iam_role.ecs_task.name
}

output "task_role_id" {
  description = <<-EOT
    Unique identifier (ID) of the ECS task role.
    
    This is the stable identifier that doesn't change even if
    the role is renamed.
  EOT
  value       = aws_iam_role.ecs_task.unique_id
}

# =============================================================================
# SUMMARY OUTPUT
# =============================================================================
# Consolidated output providing all role ARNs for easy reference.
# Useful for debugging and documentation purposes.
# -----------------------------------------------------------------------------

output "role_arns" {
  description = <<-EOT
    Map of all IAM role ARNs created by this module.
    
    Keys:
    - github_actions: Role for CI/CD workflows
    - task_execution: Role for ECS agent (startup permissions)
    - task: Role for container runtime
    
    Example usage:
      module.iam.role_arns["github_actions"]
  EOT
  value = {
    github_actions = aws_iam_role.github_actions.arn
    task_execution = aws_iam_role.ecs_task_execution.arn
    task           = aws_iam_role.ecs_task.arn
  }
}

output "role_names" {
  description = <<-EOT
    Map of all IAM role names created by this module.
    
    Keys:
    - github_actions: Role name for CI/CD workflows
    - task_execution: Role name for ECS agent
    - task: Role name for container runtime
    
    Example usage:
      module.iam.role_names["task_execution"]
  EOT
  value = {
    github_actions = aws_iam_role.github_actions.name
    task_execution = aws_iam_role.ecs_task_execution.name
    task           = aws_iam_role.ecs_task.name
  }
}
