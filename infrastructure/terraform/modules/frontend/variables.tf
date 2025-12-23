# -----------------------------------------------------------------------------
# Frontend Module - Input Variables
# -----------------------------------------------------------------------------
# Variables for configuring S3 static hosting and CloudFront CDN
# for the React/Vite frontend application.
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, production)"
  type        = string
}

variable "bucket_name" {
  description = "Name of the S3 bucket for frontend static assets"
  type        = string
}

variable "force_destroy" {
  description = "Allow destruction of non-empty bucket"
  type        = bool
  default     = false
}

variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.price_class)
    error_message = "Price class must be one of: PriceClass_100, PriceClass_200, PriceClass_All."
  }
}

variable "default_ttl" {
  description = "Default TTL in seconds for CloudFront cache"
  type        = number
  default     = 86400
}

variable "max_ttl" {
  description = "Maximum TTL in seconds for CloudFront cache"
  type        = number
  default     = 31536000
}

variable "min_ttl" {
  description = "Minimum TTL in seconds for CloudFront cache"
  type        = number
  default     = 0
}

variable "default_root_object" {
  description = "Default root object for CloudFront distribution"
  type        = string
  default     = "index.html"
}

variable "tags" {
  description = "Tags to apply to frontend resources"
  type        = map(string)
  default     = {}
}
