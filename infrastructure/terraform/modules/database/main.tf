# -----------------------------------------------------------------------------
# Database Module - Main Configuration
# -----------------------------------------------------------------------------
# Creates the DynamoDB table for conversation persistence.
#
# Table Configuration:
#   - Name: langgraph-conversations (matches backend/app/config.py)
#   - Partition Key: session_id (String) - supports session-based access pattern
#   - Sort Key: timestamp (Number) - enables chronological message retrieval
#   - Billing: PAY_PER_REQUEST (on-demand scaling for variable/unpredictable workloads)
#   - TTL: Enabled on 'expiration' attribute for automatic session cleanup
#   - PITR: Point-in-time recovery for production data protection
#   - Encryption: Server-side encryption enabled for data at rest security
#
# Future-Ready Design:
#   This table is provisioned but not actively used by the application.
#   The current implementation uses in-memory state (MemorySaver), but the
#   table is ready for conversation persistence when the application
#   implements storage functionality.
#
# Reference: backend/app/config.py line 8 - DYNAMODB_TABLE = "langgraph-conversations"
# -----------------------------------------------------------------------------

locals {
  # Module-specific tags merged with passed-in tags
  default_tags = {
    Module = "database"
  }
  merged_tags = merge(local.default_tags, var.tags)
}

# -----------------------------------------------------------------------------
# DynamoDB Table for Conversations
# -----------------------------------------------------------------------------
# This table stores conversation sessions with the following access patterns:
#   - Query sessions by session_id (partition key)
#   - Retrieve messages in chronological order within a session (sort key)
#   - Automatic cleanup of expired sessions via TTL
# -----------------------------------------------------------------------------
resource "aws_dynamodb_table" "conversations" {
  name         = var.table_name
  billing_mode = var.billing_mode

  # Primary key configuration
  # session_id: Partition key for session-based queries
  hash_key = "session_id"
  # timestamp: Sort key for chronological message ordering within sessions
  range_key = "timestamp"

  # Only set provisioned capacity if billing mode is PROVISIONED
  # PAY_PER_REQUEST mode automatically scales and doesn't use these values
  read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null

  # -----------------------------------------------------------------------------
  # Attribute Definitions
  # -----------------------------------------------------------------------------
  # session_id: String type - unique identifier for each conversation session
  attribute {
    name = "session_id"
    type = "S"
  }

  # timestamp: Number type - Unix timestamp for message ordering
  # Using Number type for efficient range queries and sorting
  attribute {
    name = "timestamp"
    type = "N"
  }

  # -----------------------------------------------------------------------------
  # Time To Live (TTL) Configuration
  # -----------------------------------------------------------------------------
  # Enables automatic deletion of expired items based on the expiration attribute.
  # The application is responsible for setting the 'expiration' attribute value
  # when creating/updating items. Items with expiration timestamps in the past
  # are automatically deleted by DynamoDB (within 48 hours typically).
  dynamic "ttl" {
    for_each = var.ttl_enabled ? [1] : []
    content {
      attribute_name = var.ttl_attribute_name
      enabled        = true
    }
  }

  # -----------------------------------------------------------------------------
  # Point-in-Time Recovery (PITR)
  # -----------------------------------------------------------------------------
  # Provides continuous backups of table data, allowing restoration to any
  # point in time within the retention period (up to 35 days).
  # Recommended for production workloads to protect against accidental writes
  # or deletes.
  point_in_time_recovery {
    enabled = var.point_in_time_recovery_enabled
  }

  # -----------------------------------------------------------------------------
  # Server-Side Encryption
  # -----------------------------------------------------------------------------
  # Encrypts data at rest using AWS managed keys (default) or customer-managed
  # KMS keys. This ensures compliance with data protection requirements.
  # Using AWS owned key (SSE-OWNED) by default - no additional cost.
  server_side_encryption {
    enabled = true
    # Optionally specify a KMS key ARN for customer-managed encryption:
    # kms_key_arn = var.kms_key_arn
  }

  # -----------------------------------------------------------------------------
  # Resource Tags
  # -----------------------------------------------------------------------------
  # Apply common tags plus the table name for easy identification
  tags = merge(local.merged_tags, {
    Name = var.table_name
  })

  # Lifecycle configuration to prevent accidental destruction in production
  lifecycle {
    prevent_destroy = false # Set to true for production environments
  }
}

# -----------------------------------------------------------------------------
# Optional: Global Secondary Index (GSI) Support
# -----------------------------------------------------------------------------
# If additional access patterns are needed in the future, GSIs can be added.
# Example use case: Query conversations by user_id across all sessions.
#
# This is commented out as it's not currently required, but the structure
# is provided for future reference:
#
# resource "aws_dynamodb_table" "conversations" {
#   ...
#   global_secondary_index {
#     name               = "user-index"
#     hash_key           = "user_id"
#     range_key          = "timestamp"
#     projection_type    = "ALL"
#   }
#   ...
# }
# -----------------------------------------------------------------------------
