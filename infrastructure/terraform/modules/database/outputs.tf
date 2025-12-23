# -----------------------------------------------------------------------------
# Database Module - Output Values
# -----------------------------------------------------------------------------
# Exports DynamoDB table identifiers for use by ECS and IAM modules.
# -----------------------------------------------------------------------------

output "table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.conversations.name
}

output "table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.conversations.arn
}

output "table_id" {
  description = "ID of the DynamoDB table"
  value       = aws_dynamodb_table.conversations.id
}

output "table_stream_arn" {
  description = "ARN of the DynamoDB table stream (if enabled)"
  value       = aws_dynamodb_table.conversations.stream_arn
}
