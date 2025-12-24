# -----------------------------------------------------------------------------
# Database Module - Output Values
# -----------------------------------------------------------------------------
# This file exports DynamoDB table identifiers for consumption by other modules
# and the root module. These outputs enable:
#
# - ECS task definitions to inject DYNAMODB_TABLE_NAME environment variable
# - IAM module to create DynamoDB access policies with table ARN
# - Root module outputs for CI/CD workflow reference
# - Monitoring module to configure CloudWatch alarms on table metrics
#
# Output Consumers:
#   - modules/iam/main.tf: Uses table_arn for IAM policy resources
#   - modules/ecs-fargate/main.tf: Uses table_name for container environment
#   - Root outputs.tf: Passes through for CI/CD and external reference
#
# Table Reference: backend/app/config.py - DYNAMODB_TABLE = "langgraph-conversations"
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Primary Output: Table Name
# -----------------------------------------------------------------------------
# The logical name of the DynamoDB table. This value is passed to ECS task
# definitions as the DYNAMODB_TABLE_NAME environment variable, matching the
# configuration expected by the backend application (backend/app/config.py).
#
# Usage in ECS Task Definition:
#   environment {
#     name  = "DYNAMODB_TABLE_NAME"
#     value = module.database.table_name
#   }
# -----------------------------------------------------------------------------
output "table_name" {
  description = "Name of the DynamoDB table for conversation persistence. Used by ECS task definition environment variables."
  value       = aws_dynamodb_table.conversations.name
}

# -----------------------------------------------------------------------------
# Primary Output: Table ARN
# -----------------------------------------------------------------------------
# The Amazon Resource Name (ARN) of the DynamoDB table. This is required for
# creating IAM policies that grant DynamoDB access to ECS tasks. The ARN format:
# arn:aws:dynamodb:{region}:{account-id}:table/{table-name}
#
# Usage in IAM Policy:
#   resources = [module.database.table_arn]
#   actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:Query", ...]
# -----------------------------------------------------------------------------
output "table_arn" {
  description = "ARN of the DynamoDB table for IAM policy configuration and resource references."
  value       = aws_dynamodb_table.conversations.arn
}

# -----------------------------------------------------------------------------
# Secondary Output: Table ID
# -----------------------------------------------------------------------------
# The unique identifier for the DynamoDB table (same as table name in DynamoDB).
# Provided for completeness and potential use in resource references where ID
# is preferred over name.
# -----------------------------------------------------------------------------
output "table_id" {
  description = "ID of the DynamoDB table (equivalent to table name in DynamoDB)."
  value       = aws_dynamodb_table.conversations.id
}

# -----------------------------------------------------------------------------
# Optional Output: DynamoDB Stream ARN
# -----------------------------------------------------------------------------
# The ARN of the DynamoDB Streams endpoint for this table, if streams are
# enabled. DynamoDB Streams capture item-level modifications in DynamoDB tables
# and can be used for:
#   - Triggering Lambda functions on data changes
#   - Cross-region replication
#   - Real-time analytics pipelines
#
# Note: This output returns null if streams are not enabled on the table.
# The try() function ensures graceful handling of the null/empty case.
#
# Stream types supported:
#   - KEYS_ONLY: Only the key attributes of modified item
#   - NEW_IMAGE: The entire item after modification
#   - OLD_IMAGE: The entire item before modification
#   - NEW_AND_OLD_IMAGES: Both old and new images
# -----------------------------------------------------------------------------
output "stream_arn" {
  description = "ARN of the DynamoDB table stream for event-driven processing (null if streams not enabled)."
  value       = try(aws_dynamodb_table.conversations.stream_arn, null)
}

# -----------------------------------------------------------------------------
# Optional Output: Stream Label
# -----------------------------------------------------------------------------
# A timestamp in ISO 8601 format that uniquely identifies the stream for the
# DynamoDB table. This label is useful for identifying streams when multiple
# streams have been enabled over the table's lifetime.
#
# Returns null if streams are not enabled.
# -----------------------------------------------------------------------------
output "stream_label" {
  description = "Timestamp label uniquely identifying the DynamoDB stream (null if streams not enabled)."
  value       = try(aws_dynamodb_table.conversations.stream_label, null)
}

# -----------------------------------------------------------------------------
# Computed Output: Table Index ARN Pattern
# -----------------------------------------------------------------------------
# ARN pattern for all indexes on this table. Useful for IAM policies that need
# to grant access to Global Secondary Indexes (GSIs) or Local Secondary Indexes.
#
# IAM policies often need permissions on both the table and its indexes:
#   resources = [
#     module.database.table_arn,
#     module.database.table_index_arn
#   ]
# -----------------------------------------------------------------------------
output "table_index_arn" {
  description = "ARN pattern for DynamoDB table indexes (table_arn/index/*) for IAM policy configuration."
  value       = "${aws_dynamodb_table.conversations.arn}/index/*"
}

# -----------------------------------------------------------------------------
# Billing Information Output
# -----------------------------------------------------------------------------
# The billing mode of the table (PROVISIONED or PAY_PER_REQUEST). This is useful
# for monitoring and cost management integrations that need to understand the
# table's capacity mode.
# -----------------------------------------------------------------------------
output "billing_mode" {
  description = "Billing mode of the DynamoDB table (PROVISIONED or PAY_PER_REQUEST)."
  value       = aws_dynamodb_table.conversations.billing_mode
}

# -----------------------------------------------------------------------------
# Hash Key Output
# -----------------------------------------------------------------------------
# The partition key (hash key) attribute name. Useful for applications that
# need to dynamically construct queries or for documentation purposes.
# -----------------------------------------------------------------------------
output "hash_key" {
  description = "Name of the partition key (hash key) attribute for the DynamoDB table."
  value       = aws_dynamodb_table.conversations.hash_key
}

# -----------------------------------------------------------------------------
# Range Key Output
# -----------------------------------------------------------------------------
# The sort key (range key) attribute name, if defined. Useful for applications
# that need to dynamically construct queries with sort conditions.
# Returns null if no range key is configured.
# -----------------------------------------------------------------------------
output "range_key" {
  description = "Name of the sort key (range key) attribute for the DynamoDB table (null if not defined)."
  value       = try(aws_dynamodb_table.conversations.range_key, null)
}
