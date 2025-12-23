# -----------------------------------------------------------------------------
# Database Module - Input Variables
# -----------------------------------------------------------------------------
# Variables for configuring the DynamoDB table for conversation persistence.
# -----------------------------------------------------------------------------

variable "table_name" {
  description = "Name of the DynamoDB table"
  type        = string
  default     = "langgraph-conversations"
}

variable "billing_mode" {
  description = "DynamoDB billing mode (PAY_PER_REQUEST or PROVISIONED)"
  type        = string
  default     = "PAY_PER_REQUEST"

  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.billing_mode)
    error_message = "Billing mode must be either PAY_PER_REQUEST or PROVISIONED."
  }
}

variable "ttl_enabled" {
  description = "Enable TTL for automatic expiration of old sessions"
  type        = bool
  default     = true
}

variable "ttl_attribute_name" {
  description = "Name of the TTL attribute"
  type        = string
  default     = "expiration"
}

variable "point_in_time_recovery_enabled" {
  description = "Enable point-in-time recovery for the table"
  type        = bool
  default     = true
}

variable "read_capacity" {
  description = "Read capacity units (only used with PROVISIONED billing)"
  type        = number
  default     = 5
}

variable "write_capacity" {
  description = "Write capacity units (only used with PROVISIONED billing)"
  type        = number
  default     = 5
}

variable "tags" {
  description = "Tags to apply to database resources"
  type        = map(string)
  default     = {}
}
