# -----------------------------------------------------------------------------
# Storage Module - Main Configuration
# -----------------------------------------------------------------------------
# Creates infrastructure for Terraform remote state management:
# - S3 bucket for state file storage with versioning and encryption
# - DynamoDB table for state locking to prevent concurrent modifications
# -----------------------------------------------------------------------------

locals {
  default_tags = {
    Module = "storage"
  }
  merged_tags = merge(local.default_tags, var.tags)
}

# -----------------------------------------------------------------------------
# S3 Bucket for Terraform State
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
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

# -----------------------------------------------------------------------------
# S3 Bucket Server-Side Encryption
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
resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# DynamoDB Table for State Locking
# -----------------------------------------------------------------------------
resource "aws_dynamodb_table" "locks" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(local.merged_tags, {
    Name    = var.lock_table_name
    Purpose = "terraform-state-locking"
  })
}
