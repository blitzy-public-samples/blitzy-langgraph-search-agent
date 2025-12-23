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
# Note: Placeholder values are created. Actual secret values should be
# updated via AWS Console or CLI after deployment.
# -----------------------------------------------------------------------------

locals {
  default_tags = {
    Module = "secrets"
  }
  merged_tags = merge(local.default_tags, var.tags)

  # Secret names following pattern: {project}/{environment}/{secret-name}
  openai_secret_name = "${var.project_name}/${var.environment}/openai-api-key"
  tavily_secret_name = "${var.project_name}/${var.environment}/tavily-api-key"
}

# -----------------------------------------------------------------------------
# OpenAI API Key Secret
# -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "openai" {
  count = var.create_openai_secret ? 1 : 0

  name                    = local.openai_secret_name
  description             = "OpenAI API key for LangGraph Search Agent LLM interactions"
  recovery_window_in_days = var.recovery_window_in_days

  tags = merge(local.merged_tags, {
    Name       = local.openai_secret_name
    SecretType = "api-key"
  })
}

resource "aws_secretsmanager_secret_version" "openai" {
  count = var.create_openai_secret ? 1 : 0

  secret_id = aws_secretsmanager_secret.openai[0].id
  secret_string = jsonencode({
    api_key = "PLACEHOLDER_REPLACE_ME"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# -----------------------------------------------------------------------------
# Tavily API Key Secret
# -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "tavily" {
  count = var.create_tavily_secret ? 1 : 0

  name                    = local.tavily_secret_name
  description             = "Tavily API key for LangGraph Search Agent web search functionality"
  recovery_window_in_days = var.recovery_window_in_days

  tags = merge(local.merged_tags, {
    Name       = local.tavily_secret_name
    SecretType = "api-key"
  })
}

resource "aws_secretsmanager_secret_version" "tavily" {
  count = var.create_tavily_secret ? 1 : 0

  secret_id = aws_secretsmanager_secret.tavily[0].id
  secret_string = jsonencode({
    api_key = "PLACEHOLDER_REPLACE_ME"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}
