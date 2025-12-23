# -----------------------------------------------------------------------------
# Secrets Module - Input Variables
# -----------------------------------------------------------------------------
# Variables for configuring AWS Secrets Manager secrets for API keys
# and other sensitive configuration values.
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, production)"
  type        = string
}

variable "recovery_window_in_days" {
  description = "Number of days before secret is permanently deleted"
  type        = number
  default     = 7

  validation {
    condition     = var.recovery_window_in_days >= 0 && var.recovery_window_in_days <= 30
    error_message = "Recovery window must be between 0 and 30 days."
  }
}

variable "create_openai_secret" {
  description = "Create a Secrets Manager secret for OpenAI API key"
  type        = bool
  default     = true
}

variable "create_tavily_secret" {
  description = "Create a Secrets Manager secret for Tavily API key"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to secrets resources"
  type        = map(string)
  default     = {}
}
