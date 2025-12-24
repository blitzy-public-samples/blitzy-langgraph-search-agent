# -----------------------------------------------------------------------------
# Secrets Module - Input Variables
# -----------------------------------------------------------------------------
# Comprehensive input variable declarations for AWS Secrets Manager configuration.
# This module manages API key secrets (OpenAI, Tavily) with configurable
# recovery windows, resource policies, and ECS task role access.
# -----------------------------------------------------------------------------

# =============================================================================
# PROJECT IDENTIFICATION VARIABLES
# =============================================================================

variable "project_name" {
  description = "Name of the project used for resource naming and tagging"
  type        = string
  default     = "langgraph-search-agent"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod, or production)"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["dev", "staging", "prod", "production"], var.environment)
    error_message = "Environment must be dev, staging, prod, or production."
  }
}

# =============================================================================
# RESOURCE TAGGING VARIABLES
# =============================================================================

variable "tags" {
  description = "Common tags to apply to all resources created by this module"
  type        = map(string)
  default     = {}
}

# =============================================================================
# SECRET CONFIGURATION VARIABLES
# =============================================================================

variable "recovery_window_in_days" {
  description = "Number of days Secrets Manager waits before permanently deleting a secret. Set to 0 for immediate deletion (not recommended for production)."
  type        = number
  default     = 7

  validation {
    condition     = var.recovery_window_in_days >= 0 && var.recovery_window_in_days <= 30
    error_message = "Recovery window must be between 0 and 30 days."
  }
}

variable "create_openai_secret" {
  description = "Whether to create a Secrets Manager secret for the OpenAI API key"
  type        = bool
  default     = true
}

variable "create_tavily_secret" {
  description = "Whether to create a Secrets Manager secret for the Tavily API key"
  type        = bool
  default     = true
}

# =============================================================================
# OPTIONAL INITIAL SECRET VALUES
# =============================================================================
# These variables allow setting initial secret values during Terraform apply.
# WARNING: For production use, update secrets via AWS Console or CLI after
# initial provisioning to avoid storing sensitive values in Terraform state.
# =============================================================================

variable "openai_api_key_value" {
  description = "Initial value for OpenAI API key. Use for initial setup only; update via AWS Console/CLI for production. Leave empty to create an empty secret placeholder."
  type        = string
  default     = ""
  sensitive   = true

  validation {
    condition     = var.openai_api_key_value == "" || can(regex("^sk-", var.openai_api_key_value))
    error_message = "OpenAI API key should start with 'sk-' or be empty."
  }
}

variable "tavily_api_key_value" {
  description = "Initial value for Tavily API key. Use for initial setup only; update via AWS Console/CLI for production. Leave empty to create an empty secret placeholder."
  type        = string
  default     = ""
  sensitive   = true

  validation {
    condition     = var.tavily_api_key_value == "" || can(regex("^tvly-", var.tavily_api_key_value))
    error_message = "Tavily API key should start with 'tvly-' or be empty."
  }
}

# =============================================================================
# RESOURCE POLICY CONFIGURATION
# =============================================================================
# Configure IAM resource policies to control access to secrets.
# Use these variables to grant ECS tasks direct access to secrets.
# =============================================================================

variable "create_secret_policy" {
  description = "Whether to create IAM resource policies for the secrets. When true, ECS task roles specified in ecs_task_role_arns will be granted access."
  type        = bool
  default     = false
}

variable "ecs_task_role_arns" {
  description = "List of ECS task role ARNs allowed to access the secrets. Only used when create_secret_policy is true."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for arn in var.ecs_task_role_arns : can(regex("^arn:aws:iam::[0-9]{12}:role/", arn))
    ])
    error_message = "Each ECS task role ARN must be a valid IAM role ARN in the format 'arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME'."
  }
}

variable "ecs_execution_role_arns" {
  description = "List of ECS task execution role ARNs allowed to read secrets during task startup. Only used when create_secret_policy is true."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for arn in var.ecs_execution_role_arns : can(regex("^arn:aws:iam::[0-9]{12}:role/", arn))
    ])
    error_message = "Each ECS execution role ARN must be a valid IAM role ARN in the format 'arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME'."
  }
}

# =============================================================================
# SECRET NAMING CONFIGURATION
# =============================================================================

variable "secret_name_prefix" {
  description = "Prefix for secret names. Defaults to project_name/environment if not specified."
  type        = string
  default     = ""
}

variable "openai_secret_name" {
  description = "Custom name for the OpenAI API key secret. If empty, uses default naming convention."
  type        = string
  default     = ""
}

variable "tavily_secret_name" {
  description = "Custom name for the Tavily API key secret. If empty, uses default naming convention."
  type        = string
  default     = ""
}

# =============================================================================
# KMS ENCRYPTION CONFIGURATION
# =============================================================================

variable "kms_key_id" {
  description = "ARN or ID of the KMS key to use for encrypting secrets. If not specified, AWS managed key (aws/secretsmanager) is used."
  type        = string
  default     = null
}

# =============================================================================
# SECRET ROTATION CONFIGURATION
# =============================================================================

variable "enable_rotation" {
  description = "Whether to enable automatic rotation for secrets. Requires a rotation Lambda function."
  type        = bool
  default     = false
}

variable "rotation_lambda_arn" {
  description = "ARN of the Lambda function to use for secret rotation. Required if enable_rotation is true."
  type        = string
  default     = null

  validation {
    condition     = var.rotation_lambda_arn == null || can(regex("^arn:aws:lambda:", var.rotation_lambda_arn))
    error_message = "Rotation Lambda ARN must be a valid Lambda function ARN."
  }
}

variable "rotation_days" {
  description = "Number of days between automatic scheduled rotations of the secret."
  type        = number
  default     = 30

  validation {
    condition     = var.rotation_days >= 1 && var.rotation_days <= 365
    error_message = "Rotation days must be between 1 and 365."
  }
}

# =============================================================================
# ADDITIONAL SECRETS CONFIGURATION
# =============================================================================

variable "additional_secrets" {
  description = "Map of additional secrets to create. Key is the secret identifier, value is a map with 'name', 'description', and optional 'value' fields."
  type = map(object({
    name        = string
    description = optional(string, "")
    value       = optional(string, "")
  }))
  default   = {}
  sensitive = true
}
