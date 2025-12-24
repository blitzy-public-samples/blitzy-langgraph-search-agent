# -----------------------------------------------------------------------------
# Secrets Module - Main Configuration
# -----------------------------------------------------------------------------
# Creates AWS Secrets Manager secrets for storing API keys and other
# sensitive configuration values required by the LangGraph Search Agent.
#
# Secrets Created:
# - OPENAI_API_KEY: OpenAI API key for LLM interactions
# - TAVILY_API_KEY: Tavily API key for web search functionality
#
# Features:
# - Configurable recovery window for secret deletion protection
# - Optional KMS encryption with customer-managed keys
# - Resource policies for fine-grained ECS task access control
# - Optional secret rotation with Lambda integration
# - Support for additional custom secrets via variable
# - Environment-specific naming convention
#
# Integration Points:
# - backend/app/config.py: OPENAI_API_KEY, TAVILY_API_KEY environment variables
# - ECS Task Definition: Secrets injected as environment variables
# - IAM Module: Task execution role requires secretsmanager:GetSecretValue
#
# Note: Placeholder values are created initially. Actual secret values should be
# updated via AWS Console or CLI after deployment to avoid storing sensitive
# values in Terraform state.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Local Values
# -----------------------------------------------------------------------------
# Define computed values, default tags, and naming conventions for secrets.
# These locals standardize naming and tagging across all resources.
# -----------------------------------------------------------------------------
locals {
  # Default tags applied to all resources in this module
  default_tags = {
    Module = "secrets"
  }

  # Merge default tags with user-provided tags
  # User tags take precedence over default tags in case of conflicts
  merged_tags = merge(local.default_tags, var.tags)

  # Determine the secret name prefix
  # Use custom prefix if provided, otherwise use project/environment pattern
  secret_prefix = var.secret_name_prefix != "" ? var.secret_name_prefix : "${var.project_name}-${var.environment}"

  # Secret names following pattern: {prefix}-{secret-name}
  # Custom names override the default naming convention
  openai_secret_name = var.openai_secret_name != "" ? var.openai_secret_name : "${local.secret_prefix}-openai-api-key"
  tavily_secret_name = var.tavily_secret_name != "" ? var.tavily_secret_name : "${local.secret_prefix}-tavily-api-key"

  # Combine task role and execution role ARNs for policy principals
  # Both need access to secrets for ECS task startup and runtime
  all_role_arns = concat(var.ecs_task_role_arns, var.ecs_execution_role_arns)
}

# -----------------------------------------------------------------------------
# OpenAI API Key Secret
# -----------------------------------------------------------------------------
# Stores the OpenAI API key used by the LangGraph Search Agent backend
# for LLM interactions. The backend retrieves this secret at container
# startup via ECS task definition secret injection.
#
# Configuration:
# - name: Follows {project}-{environment}-openai-api-key pattern
# - recovery_window_in_days: Configurable deletion protection period
# - kms_key_id: Optional customer-managed KMS key for encryption
#
# Related Files:
# - backend/app/config.py: Settings.OPENAI_API_KEY
# - backend-deploy.yml: Secret injected via ECS task definition
# -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "openai" {
  count = var.create_openai_secret ? 1 : 0

  name                    = local.openai_secret_name
  description             = "OpenAI API key for LangGraph Search Agent LLM interactions"
  recovery_window_in_days = var.recovery_window_in_days

  # Optional KMS encryption with customer-managed key
  # If not specified, AWS managed key (aws/secretsmanager) is used
  kms_key_id = var.kms_key_id

  tags = merge(local.merged_tags, {
    Name       = local.openai_secret_name
    SecretType = "api-key"
    Service    = "openai"
  })
}

# -----------------------------------------------------------------------------
# OpenAI API Key Secret Version
# -----------------------------------------------------------------------------
# Creates the initial version of the OpenAI API key secret.
# Uses placeholder value if no actual key is provided via variable.
#
# IMPORTANT: The lifecycle block with ignore_changes prevents Terraform
# from overwriting the secret value on subsequent applies. This allows
# manual updates via AWS Console/CLI without Terraform reverting changes.
#
# Initial Setup Flow:
# 1. Terraform creates secret with placeholder value
# 2. Administrator updates secret via AWS Console/CLI with real API key
# 3. Subsequent Terraform applies preserve the manually set value
# -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret_version" "openai" {
  count = var.create_openai_secret ? 1 : 0

  secret_id     = aws_secretsmanager_secret.openai[0].id
  secret_string = var.openai_api_key_value != "" ? var.openai_api_key_value : "PLACEHOLDER_REPLACE_ME"

  lifecycle {
    # Ignore changes to secret_string to prevent overwriting manually updated secrets
    # This is critical for production secrets that are rotated or updated outside Terraform
    ignore_changes = [secret_string]
  }
}

# -----------------------------------------------------------------------------
# Tavily API Key Secret
# -----------------------------------------------------------------------------
# Stores the Tavily API key used by the LangGraph Search Agent backend
# for web search functionality. The backend retrieves this secret at
# container startup via ECS task definition secret injection.
#
# Configuration:
# - name: Follows {project}-{environment}-tavily-api-key pattern
# - recovery_window_in_days: Configurable deletion protection period
# - kms_key_id: Optional customer-managed KMS key for encryption
#
# Related Files:
# - backend/app/config.py: Settings.TAVILY_API_KEY
# - backend-deploy.yml: Secret injected via ECS task definition
# -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "tavily" {
  count = var.create_tavily_secret ? 1 : 0

  name                    = local.tavily_secret_name
  description             = "Tavily API key for LangGraph Search Agent web search functionality"
  recovery_window_in_days = var.recovery_window_in_days

  # Optional KMS encryption with customer-managed key
  # If not specified, AWS managed key (aws/secretsmanager) is used
  kms_key_id = var.kms_key_id

  tags = merge(local.merged_tags, {
    Name       = local.tavily_secret_name
    SecretType = "api-key"
    Service    = "tavily"
  })
}

# -----------------------------------------------------------------------------
# Tavily API Key Secret Version
# -----------------------------------------------------------------------------
# Creates the initial version of the Tavily API key secret.
# Uses placeholder value if no actual key is provided via variable.
#
# See OpenAI secret version comments for lifecycle management details.
# -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret_version" "tavily" {
  count = var.create_tavily_secret ? 1 : 0

  secret_id     = aws_secretsmanager_secret.tavily[0].id
  secret_string = var.tavily_api_key_value != "" ? var.tavily_api_key_value : "PLACEHOLDER_REPLACE_ME"

  lifecycle {
    # Ignore changes to secret_string to prevent overwriting manually updated secrets
    ignore_changes = [secret_string]
  }
}

# -----------------------------------------------------------------------------
# IAM Policy Document for Secrets Access
# -----------------------------------------------------------------------------
# Defines the IAM policy allowing ECS task roles and execution roles
# to read secrets. This policy is attached to each secret as a resource
# policy when create_secret_policy is enabled.
#
# Permissions Granted:
# - secretsmanager:GetSecretValue: Retrieve the secret value
# - secretsmanager:DescribeSecret: Get secret metadata
#
# Principals:
# - ECS Task Roles: Runtime access for containers
# - ECS Execution Roles: Startup access for secret injection
#
# Note: Resource policies provide an additional layer of access control
# beyond IAM policies attached to the roles themselves.
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "secrets_access" {
  count = var.create_secret_policy && length(local.all_role_arns) > 0 ? 1 : 0

  statement {
    sid    = "AllowECSTaskAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = local.all_role_arns
    }

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]

    resources = ["*"]
  }
}

# -----------------------------------------------------------------------------
# OpenAI API Key Secret Resource Policy
# -----------------------------------------------------------------------------
# Attaches an IAM resource policy to the OpenAI secret controlling which
# principals can access the secret directly. This is complementary to
# IAM policies attached to the accessing roles.
#
# When to use resource policies:
# - Explicit allow/deny rules for specific secrets
# - Cross-account access requirements
# - Restricting access to specific secrets beyond IAM role permissions
# -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret_policy" "openai" {
  count = var.create_secret_policy && var.create_openai_secret && length(local.all_role_arns) > 0 ? 1 : 0

  secret_arn = aws_secretsmanager_secret.openai[0].arn
  policy     = data.aws_iam_policy_document.secrets_access[0].json

  depends_on = [
    aws_secretsmanager_secret.openai,
    aws_secretsmanager_secret_version.openai
  ]
}

# -----------------------------------------------------------------------------
# Tavily API Key Secret Resource Policy
# -----------------------------------------------------------------------------
# Attaches an IAM resource policy to the Tavily secret controlling which
# principals can access the secret directly.
#
# See OpenAI secret policy comments for usage details.
# -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret_policy" "tavily" {
  count = var.create_secret_policy && var.create_tavily_secret && length(local.all_role_arns) > 0 ? 1 : 0

  secret_arn = aws_secretsmanager_secret.tavily[0].arn
  policy     = data.aws_iam_policy_document.secrets_access[0].json

  depends_on = [
    aws_secretsmanager_secret.tavily,
    aws_secretsmanager_secret_version.tavily
  ]
}

# -----------------------------------------------------------------------------
# Secret Rotation Configuration - OpenAI API Key
# -----------------------------------------------------------------------------
# Configures automatic rotation for the OpenAI API key secret.
# Requires a Lambda function to perform the actual rotation.
#
# Rotation Flow:
# 1. Secrets Manager invokes Lambda on schedule
# 2. Lambda creates new API key (if supported by provider)
# 3. Lambda updates secret with new key
# 4. Lambda tests new key
# 5. Lambda marks rotation complete
#
# Note: OpenAI API keys typically cannot be rotated automatically
# as OpenAI doesn't provide an API for key rotation. Manual rotation
# is recommended with immediate notification to update downstream secrets.
# -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret_rotation" "openai" {
  count = var.enable_rotation && var.create_openai_secret && var.rotation_lambda_arn != null ? 1 : 0

  secret_id           = aws_secretsmanager_secret.openai[0].id
  rotation_lambda_arn = var.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = var.rotation_days
  }

  depends_on = [
    aws_secretsmanager_secret.openai,
    aws_secretsmanager_secret_version.openai
  ]
}

# -----------------------------------------------------------------------------
# Secret Rotation Configuration - Tavily API Key
# -----------------------------------------------------------------------------
# Configures automatic rotation for the Tavily API key secret.
# See OpenAI rotation comments for detailed flow description.
# -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret_rotation" "tavily" {
  count = var.enable_rotation && var.create_tavily_secret && var.rotation_lambda_arn != null ? 1 : 0

  secret_id           = aws_secretsmanager_secret.tavily[0].id
  rotation_lambda_arn = var.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = var.rotation_days
  }

  depends_on = [
    aws_secretsmanager_secret.tavily,
    aws_secretsmanager_secret_version.tavily
  ]
}

# -----------------------------------------------------------------------------
# Additional Custom Secrets
# -----------------------------------------------------------------------------
# Creates additional secrets defined via the additional_secrets variable.
# This allows flexibility to add environment-specific secrets without
# modifying the module code.
#
# Usage Example:
# additional_secrets = {
#   "database-password" = {
#     name        = "langgraph-search-agent-prod-db-password"
#     description = "Database password for production environment"
#     value       = ""  # Empty for placeholder
#   }
#   "custom-api-key" = {
#     name        = "langgraph-search-agent-prod-custom-api"
#     description = "Custom third-party API key"
#     value       = ""
#   }
# }
# -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "additional" {
  for_each = var.additional_secrets

  name                    = each.value.name
  description             = each.value.description != "" ? each.value.description : "Additional secret: ${each.key}"
  recovery_window_in_days = var.recovery_window_in_days
  kms_key_id              = var.kms_key_id

  tags = merge(local.merged_tags, {
    Name       = each.value.name
    SecretType = "custom"
    SecretKey  = each.key
  })
}

# -----------------------------------------------------------------------------
# Additional Custom Secret Versions
# -----------------------------------------------------------------------------
# Creates initial versions for additional secrets with optional values.
# Uses placeholder if no value is provided.
# -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret_version" "additional" {
  for_each = var.additional_secrets

  secret_id     = aws_secretsmanager_secret.additional[each.key].id
  secret_string = each.value.value != "" ? each.value.value : "PLACEHOLDER_REPLACE_ME"

  lifecycle {
    # Ignore changes to allow manual updates without Terraform reverting
    ignore_changes = [secret_string]
  }
}

# -----------------------------------------------------------------------------
# Additional Secret Resource Policies
# -----------------------------------------------------------------------------
# Attaches resource policies to additional secrets when enabled.
# Uses the same policy document as the primary secrets.
# -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret_policy" "additional" {
  for_each = var.create_secret_policy && length(local.all_role_arns) > 0 ? var.additional_secrets : {}

  secret_arn = aws_secretsmanager_secret.additional[each.key].arn
  policy     = data.aws_iam_policy_document.secrets_access[0].json

  depends_on = [
    aws_secretsmanager_secret.additional,
    aws_secretsmanager_secret_version.additional
  ]
}
