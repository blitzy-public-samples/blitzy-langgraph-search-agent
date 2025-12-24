# -----------------------------------------------------------------------------
# Storage Module - Main Configuration
# -----------------------------------------------------------------------------
# Creates infrastructure for Terraform remote state management:
# - S3 bucket for state file storage with versioning and encryption
# - DynamoDB table for state locking to prevent concurrent modifications
#
# This module implements security best practices including:
# - Server-side AES256 encryption for all objects
# - Public access blocking on all endpoints
# - SSL/TLS enforcement via bucket policy
# - On-demand billing for DynamoDB to optimize costs
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Local Values
# -----------------------------------------------------------------------------
# Define module-specific tags that get merged with user-provided tags
# These tags help identify resources created by this module
# -----------------------------------------------------------------------------
locals {
  # Module-specific tags for resource identification
  module_tags = {
    Module = "storage"
  }

  # Merge module tags with user-provided tags
  # User tags take precedence over module defaults
  merged_tags = merge(local.module_tags, var.tags)
}

# -----------------------------------------------------------------------------
# S3 Bucket for Terraform State
# -----------------------------------------------------------------------------
# Primary storage for Terraform state files. This bucket serves as the
# backend for remote state management, enabling team collaboration and
# preventing state file conflicts.
#
# Note: force_destroy is configurable to allow cleanup in non-production
# environments. In production, this should be set to false to prevent
# accidental state loss.
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "state" {
  bucket        = var.state_bucket_name
  force_destroy = var.force_destroy

  tags = merge(local.merged_tags, {
    Name    = var.state_bucket_name
    Purpose = "terraform-state"
  })
}

# -----------------------------------------------------------------------------
# S3 Bucket Versioning
# -----------------------------------------------------------------------------
# Enable versioning to preserve state file history. This is critical for:
# - Recovering from accidental state corruption or deletion
# - Auditing state changes over time
# - Rolling back to previous state versions if needed
#
# Versioning should always be enabled for Terraform state buckets.
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# -----------------------------------------------------------------------------
# S3 Bucket Server-Side Encryption
# -----------------------------------------------------------------------------
# Configure AES256 server-side encryption for all objects stored in the bucket.
# This ensures all state files are encrypted at rest, protecting sensitive
# infrastructure configuration data.
#
# bucket_key_enabled reduces S3 request costs when using SSE-S3 encryption.
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# -----------------------------------------------------------------------------
# S3 Bucket Public Access Block
# -----------------------------------------------------------------------------
# Block all public access to the state bucket. Terraform state files often
# contain sensitive information including:
# - Resource identifiers and ARNs
# - Configuration values
# - Potentially sensitive outputs
#
# All four settings must be enabled to fully prevent public access.
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  # Block public ACLs - prevents new public ACLs from being created
  block_public_acls = true

  # Block public bucket policies - prevents bucket policies that grant public access
  block_public_policy = true

  # Ignore public ACLs - ignores existing public ACLs on the bucket and objects
  ignore_public_acls = true

  # Restrict public buckets - restricts access to bucket with public policies
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# S3 Bucket Policy - Enforce SSL/TLS
# -----------------------------------------------------------------------------
# This policy enforces that all requests to the bucket must be made over HTTPS.
# Non-encrypted HTTP requests are denied, ensuring data in transit is protected.
#
# The policy uses the aws:SecureTransport condition to check if the request
# was made using SSL/TLS. Requests with SecureTransport=false are denied.
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.state.id

  # Ensure public access block is applied first to avoid race conditions
  depends_on = [aws_s3_bucket_public_access_block.state]

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "EnforceSSLPolicy"
    Statement = [
      {
        Sid       = "DenyNonHTTPSAccess"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.state.arn,
          "${aws_s3_bucket.state.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# DynamoDB Table for State Locking
# -----------------------------------------------------------------------------
# This table provides state locking for Terraform operations. When Terraform
# begins an operation that could modify state, it acquires a lock to prevent
# concurrent modifications that could corrupt the state file.
#
# Configuration:
# - LockID: Partition key used by Terraform to identify the lock
# - PAY_PER_REQUEST: On-demand billing for cost optimization (state operations
#   are infrequent, making on-demand more cost-effective than provisioned)
#
# Note: Point-in-time recovery and deletion protection can be enabled for
# production environments but are not required for the lock table since
# the data is ephemeral and regenerated by Terraform operations.
# -----------------------------------------------------------------------------
resource "aws_dynamodb_table" "locks" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  # The LockID attribute is required by Terraform's S3 backend for state locking
  # It stores a unique identifier for each state file lock
  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(local.merged_tags, {
    Name    = var.lock_table_name
    Purpose = "terraform-state-locking"
  })
}
