# -----------------------------------------------------------------------------
# Secrets Module - Output Values
# -----------------------------------------------------------------------------
# Exports secret ARNs for use by ECS task definitions and IAM policies.
# These outputs enable secure integration with the ecs-fargate module for
# container secret injection at runtime.
#
# Output Categories:
# - secret_arns: Combined map for ECS task definition consumption (sensitive)
# - Individual ARN outputs: For IAM policy attachments
# - Secret name outputs: For reference and logging
# - Additional secret outputs: For dynamically created secrets
# -----------------------------------------------------------------------------

# =============================================================================
# PRIMARY OUTPUTS
# =============================================================================

output "secret_arns" {
  description = "Map of secret names to their ARNs for ECS task definition environment variable configuration. Used by ecs-fargate module for container secret injection."
  value = {
    OPENAI_API_KEY = var.create_openai_secret ? aws_secretsmanager_secret.openai[0].arn : ""
    TAVILY_API_KEY = var.create_tavily_secret ? aws_secretsmanager_secret.tavily[0].arn : ""
  }
  sensitive = true
}

# =============================================================================
# INDIVIDUAL SECRET ARN OUTPUTS
# =============================================================================
# Individual ARN outputs for direct reference by IAM policies and other modules.
# Uses consistent naming: {service}_api_key_secret_arn
# =============================================================================

output "openai_api_key_secret_arn" {
  description = "ARN of the OpenAI API key secret (aws_secretsmanager_secret.openai.arn) for IAM policy attachment and ECS task definition secret references"
  value       = var.create_openai_secret ? aws_secretsmanager_secret.openai[0].arn : ""
  sensitive   = true
}

output "tavily_api_key_secret_arn" {
  description = "ARN of the Tavily API key secret (aws_secretsmanager_secret.tavily.arn) for IAM policy attachment and ECS task definition secret references"
  value       = var.create_tavily_secret ? aws_secretsmanager_secret.tavily[0].arn : ""
  sensitive   = true
}

# =============================================================================
# SECRET NAME OUTPUTS
# =============================================================================
# Secret name outputs for reference, logging, and AWS CLI commands.
# Uses consistent naming: {service}_api_key_secret_name
# =============================================================================

output "openai_api_key_secret_name" {
  description = "Name of the OpenAI API key secret for reference and AWS CLI/Console lookup"
  value       = var.create_openai_secret ? aws_secretsmanager_secret.openai[0].name : ""
}

output "tavily_api_key_secret_name" {
  description = "Name of the Tavily API key secret for reference and AWS CLI/Console lookup"
  value       = var.create_tavily_secret ? aws_secretsmanager_secret.tavily[0].name : ""
}

# =============================================================================
# ADDITIONAL SECRET OUTPUTS
# =============================================================================

output "additional_secret_arns" {
  description = "Map of additional secret keys to their ARNs"
  value = {
    for key, secret in aws_secretsmanager_secret.additional : key => secret.arn
  }
  sensitive = true
}

output "additional_secret_names" {
  description = "Map of additional secret keys to their names"
  value = {
    for key, secret in aws_secretsmanager_secret.additional : key => secret.name
  }
}

# =============================================================================
# COMBINED ALL SECRETS OUTPUT
# =============================================================================

output "all_secret_arns" {
  description = "Combined map of all secret ARNs (primary + additional) for comprehensive IAM policy attachment"
  value = merge(
    {
      OPENAI_API_KEY = var.create_openai_secret ? aws_secretsmanager_secret.openai[0].arn : ""
      TAVILY_API_KEY = var.create_tavily_secret ? aws_secretsmanager_secret.tavily[0].arn : ""
    },
    {
      for key, secret in aws_secretsmanager_secret.additional : upper(replace(key, "-", "_")) => secret.arn
    }
  )
  sensitive = true
}
