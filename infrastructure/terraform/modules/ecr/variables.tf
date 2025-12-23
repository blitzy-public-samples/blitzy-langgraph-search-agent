# -----------------------------------------------------------------------------
# ECR Module - Input Variables
# -----------------------------------------------------------------------------
# Variables for configuring the ECR repository including naming, scanning,
# lifecycle policies, and tagging.
# -----------------------------------------------------------------------------

variable "repository_name" {
  description = "Name of the ECR repository for storing Docker images"
  type        = string
  default     = "langgraph-search-agent-backend"

  validation {
    condition     = can(regex("^[a-z0-9-/]+$", var.repository_name))
    error_message = "Repository name must contain only lowercase letters, numbers, hyphens, and forward slashes."
  }
}

variable "scan_on_push" {
  description = "Enable image scanning on push for vulnerability detection"
  type        = bool
  default     = true
}

variable "image_retention_count" {
  description = "Number of tagged images to retain via lifecycle policy"
  type        = number
  default     = 10

  validation {
    condition     = var.image_retention_count >= 1 && var.image_retention_count <= 100
    error_message = "Image retention count must be between 1 and 100."
  }
}

variable "image_tag_mutability" {
  description = "Image tag mutability setting (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "Image tag mutability must be either MUTABLE or IMMUTABLE."
  }
}

variable "force_delete" {
  description = "Force deletion of repository even if it contains images"
  type        = bool
  default     = false
}

variable "repository_policy" {
  description = "Optional repository policy JSON for cross-account access"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to ECR resources"
  type        = map(string)
  default     = {}
}
