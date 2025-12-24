# -----------------------------------------------------------------------------
# Database Module - Input Variables
# -----------------------------------------------------------------------------
# Input variable declarations for the DynamoDB database module.
# Includes table name, TTL settings, point-in-time recovery toggle, and 
# resource tags for the langgraph-conversations table used for session
# persistence and conversation history storage.
#
# Default values match the application configuration in backend/app/config.py
# where DYNAMODB_TABLE is set to "langgraph-conversations".
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Core Table Configuration
# -----------------------------------------------------------------------------

variable "table_name" {
  description = "Name of the DynamoDB table for conversation storage. Must match the DYNAMODB_TABLE setting in backend/app/config.py"
  type        = string
  default     = "langgraph-conversations"

  validation {
    condition     = can(regex("^[a-zA-Z0-9._-]+$", var.table_name)) && length(var.table_name) >= 3 && length(var.table_name) <= 255
    error_message = "Table name must be 3-255 characters and contain only alphanumeric characters, underscores, hyphens, or periods."
  }
}

variable "billing_mode" {
  description = "DynamoDB billing mode. PAY_PER_REQUEST provides on-demand scaling for variable workloads, PROVISIONED requires capacity planning"
  type        = string
  default     = "PAY_PER_REQUEST"

  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.billing_mode)
    error_message = "Billing mode must be either PAY_PER_REQUEST or PROVISIONED."
  }
}

# -----------------------------------------------------------------------------
# Key Schema Configuration
# -----------------------------------------------------------------------------

variable "hash_key" {
  description = "Partition key attribute name for session-based access pattern"
  type        = string
  default     = "session_id"
}

variable "range_key" {
  description = "Sort key attribute name for chronological message ordering within sessions"
  type        = string
  default     = "timestamp"
}

# -----------------------------------------------------------------------------
# TTL Configuration
# -----------------------------------------------------------------------------

variable "ttl_enabled" {
  description = "Enable TTL for automatic session cleanup. When enabled, items with expiration timestamps in the past are automatically deleted"
  type        = bool
  default     = true
}

variable "ttl_attribute_name" {
  description = "Name of the TTL attribute for session expiration. The attribute value should be a Unix epoch timestamp"
  type        = string
  default     = "expiration"

  validation {
    condition     = can(regex("^[a-zA-Z0-9_]+$", var.ttl_attribute_name)) && length(var.ttl_attribute_name) >= 1 && length(var.ttl_attribute_name) <= 255
    error_message = "TTL attribute name must be 1-255 characters and contain only alphanumeric characters or underscores."
  }
}

# -----------------------------------------------------------------------------
# Data Protection Configuration
# -----------------------------------------------------------------------------

variable "point_in_time_recovery_enabled" {
  description = "Enable point-in-time recovery for data protection. Allows table restoration to any point within the last 35 days"
  type        = bool
  default     = true
}

variable "deletion_protection_enabled" {
  description = "Enable deletion protection to prevent accidental table deletion"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Provisioned Capacity Configuration
# Only used when billing_mode is set to PROVISIONED
# -----------------------------------------------------------------------------

variable "read_capacity" {
  description = "Read capacity units for provisioned billing mode. Each unit provides one strongly consistent read per second for items up to 4KB"
  type        = number
  default     = 5

  validation {
    condition     = var.read_capacity >= 1 && var.read_capacity <= 40000
    error_message = "Read capacity must be between 1 and 40000 units."
  }
}

variable "write_capacity" {
  description = "Write capacity units for provisioned billing mode. Each unit provides one write per second for items up to 1KB"
  type        = number
  default     = 5

  validation {
    condition     = var.write_capacity >= 1 && var.write_capacity <= 40000
    error_message = "Write capacity must be between 1 and 40000 units."
  }
}

# -----------------------------------------------------------------------------
# Environment Configuration
# -----------------------------------------------------------------------------

variable "environment" {
  description = "Environment name for resource naming and tagging (dev, staging, prod)"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["dev", "development", "staging", "prod", "production"], var.environment)
    error_message = "Environment must be one of: dev, development, staging, prod, production."
  }
}

# -----------------------------------------------------------------------------
# Encryption Configuration
# -----------------------------------------------------------------------------

variable "server_side_encryption_enabled" {
  description = "Enable server-side encryption at rest using AWS managed keys (AES-256)"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for server-side encryption. If not specified, uses AWS managed default key"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Resource Tagging
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Tags to apply to DynamoDB table resources. Merged with module-level default tags for consistent resource tagging across the infrastructure"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Stream Configuration (for future event-driven features)
# -----------------------------------------------------------------------------

variable "stream_enabled" {
  description = "Enable DynamoDB Streams for change data capture. Useful for triggering Lambda functions on data changes"
  type        = bool
  default     = false
}

variable "stream_view_type" {
  description = "Stream view type when streams are enabled. Determines what information is written to the stream"
  type        = string
  default     = "NEW_AND_OLD_IMAGES"

  validation {
    condition     = contains(["KEYS_ONLY", "NEW_IMAGE", "OLD_IMAGE", "NEW_AND_OLD_IMAGES"], var.stream_view_type)
    error_message = "Stream view type must be one of: KEYS_ONLY, NEW_IMAGE, OLD_IMAGE, NEW_AND_OLD_IMAGES."
  }
}

# -----------------------------------------------------------------------------
# Global Table Configuration (for future multi-region support)
# -----------------------------------------------------------------------------

variable "enable_global_tables" {
  description = "Enable DynamoDB Global Tables for multi-region replication. Requires streams to be enabled"
  type        = bool
  default     = false
}

variable "replica_regions" {
  description = "List of AWS regions for Global Table replicas. Only used when enable_global_tables is true"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for r in var.replica_regions : can(regex("^[a-z]{2}-[a-z]+-[0-9]+$", r))])
    error_message = "All replica regions must be valid AWS region identifiers (e.g., us-west-2, eu-west-1)."
  }
}
