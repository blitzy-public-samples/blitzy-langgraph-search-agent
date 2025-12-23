# -----------------------------------------------------------------------------
# Secrets Module - Output Values
# -----------------------------------------------------------------------------
# Exports secret ARNs for use by ECS task definitions and IAM policies.
# -----------------------------------------------------------------------------

output "secret_arns" {
  description = "Map of secret names to their ARNs"
  value = {
    OPENAI_API_KEY = var.create_openai_secret ? aws_secretsmanager_secret.openai[0].arn : ""
    TAVILY_API_KEY = var.create_tavily_secret ? aws_secretsmanager_secret.tavily[0].arn : ""
  }
}

output "openai_secret_arn" {
  description = "ARN of the OpenAI API key secret"
  value       = var.create_openai_secret ? aws_secretsmanager_secret.openai[0].arn : ""
}

output "tavily_secret_arn" {
  description = "ARN of the Tavily API key secret"
  value       = var.create_tavily_secret ? aws_secretsmanager_secret.tavily[0].arn : ""
}

output "openai_secret_name" {
  description = "Name of the OpenAI API key secret"
  value       = var.create_openai_secret ? aws_secretsmanager_secret.openai[0].name : ""
}

output "tavily_secret_name" {
  description = "Name of the Tavily API key secret"
  value       = var.create_tavily_secret ? aws_secretsmanager_secret.tavily[0].name : ""
}
