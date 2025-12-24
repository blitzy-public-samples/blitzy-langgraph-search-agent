# -----------------------------------------------------------------------------
# Storage Module - Input Variables
# -----------------------------------------------------------------------------
# This file defines all input variables for the storage module which provisions
# S3 buckets for Terraform state storage and DynamoDB tables for state locking.
# These resources enable secure, collaborative infrastructure management with
# versioning for state recovery and locking to prevent concurrent modifications.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# S3 State Bucket Configuration
# -----------------------------------------------------------------------------

variable "state_bucket_name" {
  description = <<-EOT
    Name of the S3 bucket used for Terraform remote state storage.
    This bucket stores the terraform.tfstate file which tracks all 
    provisioned infrastructure resources. The bucket should be globally
    unique within AWS. Versioning is recommended to enable state recovery
    in case of corruption or accidental modification.
  EOT
  type        = string
  default     = "langgraph-search-agent-terraform-state"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.state_bucket_name))
    error_message = "S3 bucket name must be between 3-63 characters, start and end with a letter or number, and contain only lowercase letters, numbers, hyphens, and periods."
  }
}

variable "enable_versioning" {
  description = <<-EOT
    Whether to enable versioning on the S3 state bucket. When enabled,
    S3 keeps multiple variants of the state file, allowing recovery from
    accidental deletions or corruption. Strongly recommended for production
    environments to maintain state history and enable rollback capabilities.
  EOT
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = <<-EOT
    Whether to allow Terraform to destroy the S3 bucket even when it
    contains objects (state files). Set to false for production safety
    to prevent accidental destruction of state files. Set to true only
    for development/testing environments where state can be safely lost.
    WARNING: Setting this to true in production can result in loss of
    infrastructure state which may require manual recovery.
  EOT
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# DynamoDB Lock Table Configuration
# -----------------------------------------------------------------------------

variable "lock_table_name" {
  description = <<-EOT
    Name of the DynamoDB table used for Terraform state locking.
    This table prevents concurrent state modifications by multiple users
    or CI/CD pipelines. When one process acquires a lock, others must
    wait until it is released, ensuring state file consistency and
    preventing corruption from simultaneous writes.
  EOT
  type        = string
  default     = "langgraph-search-agent-terraform-locks"

  validation {
    condition     = can(regex("^[a-zA-Z0-9_.-]{3,255}$", var.lock_table_name))
    error_message = "DynamoDB table name must be between 3-255 characters and contain only letters, numbers, underscores, hyphens, and periods."
  }
}

# -----------------------------------------------------------------------------
# Environment Configuration
# -----------------------------------------------------------------------------

variable "environment" {
  description = <<-EOT
    Environment name for resource naming and tagging (dev/staging/prod).
    This value is used to create environment-specific resource names
    and to apply appropriate tags for cost allocation and access control.
    Default is 'production' for safety - ensures production-grade settings
    are applied unless explicitly overridden for lower environments.
  EOT
  type        = string
  default     = "production"

  validation {
    condition     = contains(["dev", "development", "staging", "prod", "production"], var.environment)
    error_message = "Environment must be one of: dev, development, staging, prod, production."
  }
}

# -----------------------------------------------------------------------------
# Resource Tagging
# -----------------------------------------------------------------------------

variable "tags" {
  description = <<-EOT
    Common tags to apply to all storage resources created by this module.
    Tags are key-value pairs that help organize resources for cost tracking,
    access control, and operational management. Recommended tags include:
    - Project: The project name (e.g., 'langgraph-search-agent')
    - Environment: The deployment environment (e.g., 'production')
    - ManagedBy: How resources are managed (e.g., 'terraform')
    - Region: AWS region where resources are deployed
  EOT
  type        = map(string)
  default     = {}
}
