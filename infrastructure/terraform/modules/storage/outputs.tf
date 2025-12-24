# -----------------------------------------------------------------------------
# Storage Module - Output Values
# -----------------------------------------------------------------------------
# Exports S3 bucket and DynamoDB table identifiers for consumption by the
# root module backend configuration and other dependent modules.
#
# These outputs enable:
# - Terraform backend configuration using the state bucket
# - IAM policy creation referencing bucket and table ARNs
# - Integration with monitoring and logging modules
# - Root module composition and inter-module dependencies
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# S3 State Bucket Outputs
# -----------------------------------------------------------------------------
# Expose various attributes of the Terraform state S3 bucket for downstream
# consumption. The bucket stores Terraform state files and should be
# referenced in backend configurations.
# -----------------------------------------------------------------------------

output "state_bucket_id" {
  description = "The ID of the S3 bucket for Terraform state storage. Use this for backend configuration and bucket references."
  value       = aws_s3_bucket.state.id
}

output "state_bucket_arn" {
  description = "The ARN of the S3 bucket for Terraform state storage. Use this for IAM policy resource specifications."
  value       = aws_s3_bucket.state.arn
}

output "state_bucket_name" {
  description = "The name (bucket) of the S3 bucket for Terraform state storage. Use this in backend.tf configuration blocks."
  value       = aws_s3_bucket.state.bucket
}

output "state_bucket_domain_name" {
  description = "The regional domain name of the S3 bucket for Terraform state storage. Format: bucket-name.s3.region.amazonaws.com"
  value       = aws_s3_bucket.state.bucket_regional_domain_name
}

# -----------------------------------------------------------------------------
# DynamoDB Lock Table Outputs
# -----------------------------------------------------------------------------
# Expose attributes of the DynamoDB table used for Terraform state locking.
# State locking prevents concurrent modifications to the state file,
# ensuring consistency in team environments.
# -----------------------------------------------------------------------------

output "dynamodb_lock_table_name" {
  description = "The name of the DynamoDB table used for Terraform state locking. Use this in backend.tf dynamodb_table configuration."
  value       = aws_dynamodb_table.locks.name
}

output "dynamodb_lock_table_arn" {
  description = "The ARN of the DynamoDB table used for Terraform state locking. Use this for IAM policy resource specifications."
  value       = aws_dynamodb_table.locks.arn
}

output "dynamodb_lock_table_id" {
  description = "The ID of the DynamoDB table used for Terraform state locking. Equivalent to the table name in DynamoDB."
  value       = aws_dynamodb_table.locks.id
}
