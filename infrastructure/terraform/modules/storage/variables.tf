# -----------------------------------------------------------------------------
# Storage Module - Input Variables
# -----------------------------------------------------------------------------
# Variables for configuring S3 buckets and DynamoDB tables for
# Terraform state management.
# -----------------------------------------------------------------------------

variable "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state storage"
  type        = string
}

variable "lock_table_name" {
  description = "Name of the DynamoDB table for Terraform state locking"
  type        = string
}

variable "enable_versioning" {
  description = "Enable versioning on the state bucket"
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "Allow destruction of non-empty bucket"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to storage resources"
  type        = map(string)
  default     = {}
}
