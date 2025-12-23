# -----------------------------------------------------------------------------
# Database Module - Main Configuration
# -----------------------------------------------------------------------------
# Creates the DynamoDB table for conversation persistence:
# - Table name: langgraph-conversations (matches backend/app/config.py)
# - Partition key: session_id (String)
# - Sort key: timestamp (Number)
# - Billing: PAY_PER_REQUEST (on-demand scaling)
# - TTL: Enabled on 'expiration' attribute for automatic cleanup
#
# Note: This table is provisioned for future use. The current application
# uses in-memory state (MemorySaver) but the table is ready for when
# conversation persistence is implemented.
# -----------------------------------------------------------------------------

locals {
  default_tags = {
    Module = "database"
  }
  merged_tags = merge(local.default_tags, var.tags)
}

# -----------------------------------------------------------------------------
# DynamoDB Table for Conversations
# -----------------------------------------------------------------------------
resource "aws_dynamodb_table" "conversations" {
  name         = var.table_name
  billing_mode = var.billing_mode
  hash_key     = "session_id"
  range_key    = "timestamp"

  # Only set capacity if using PROVISIONED billing mode
  read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null

  attribute {
    name = "session_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  # TTL configuration for automatic expiration of old sessions
  dynamic "ttl" {
    for_each = var.ttl_enabled ? [1] : []
    content {
      attribute_name = var.ttl_attribute_name
      enabled        = true
    }
  }

  # Point-in-time recovery for data protection
  point_in_time_recovery {
    enabled = var.point_in_time_recovery_enabled
  }

  tags = merge(local.merged_tags, {
    Name = var.table_name
  })
}
