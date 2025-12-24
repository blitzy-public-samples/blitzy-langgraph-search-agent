# -----------------------------------------------------------------------------
# Frontend Module - Input Variables
# -----------------------------------------------------------------------------
# Variables for configuring S3 static hosting and CloudFront CDN
# for the React/Vite frontend application.
#
# This module provisions:
# - S3 bucket with static website hosting for frontend assets
# - CloudFront distribution for global content delivery
# - Origin Access Identity for secure S3 access
# - S3 bucket policy restricting access to CloudFront only
#
# Usage:
#   module "frontend" {
#     source       = "./modules/frontend"
#     project_name = "langgraph-search-agent"
#     environment  = "production"
#     bucket_name  = "langgraph-search-agent-frontend-production"
#   }
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Project Identification Variables
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Name of the project for resource naming. Used to generate consistent naming across all frontend resources including S3 bucket tags, CloudFront distribution comments, and Origin Access Identity comments."
  type        = string

  validation {
    condition     = length(var.project_name) > 0 && length(var.project_name) <= 63
    error_message = "Project name must be between 1 and 63 characters."
  }
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod, production). Determines resource sizing, caching strategies, and is used for resource tagging and naming conventions."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "production"], var.environment)
    error_message = "Environment must be dev, staging, prod, or production."
  }
}

# -----------------------------------------------------------------------------
# S3 Bucket Configuration Variables
# -----------------------------------------------------------------------------

variable "bucket_name" {
  description = "Name of the S3 bucket for frontend static assets. Must be globally unique across all AWS accounts. For production, this should match the S3_BUCKET value in frontend-deploy.yml (langgraph-search-agent-frontend-production)."
  type        = string

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "Bucket name must be between 3 and 63 characters."
  }

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must start and end with a lowercase letter or number, and can only contain lowercase letters, numbers, hyphens, and periods."
  }
}

variable "force_destroy" {
  description = "Allow deletion of S3 bucket with objects still inside. Set to true for development/staging environments where buckets may need to be recreated frequently. Use with caution in production."
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# CloudFront Distribution Configuration Variables
# -----------------------------------------------------------------------------

variable "price_class" {
  description = "CloudFront price class determining edge location availability. PriceClass_100 covers North America and Europe (lowest cost), PriceClass_200 adds Asia, Middle East, and Africa, PriceClass_All includes all edge locations (highest performance)."
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.price_class)
    error_message = "Price class must be PriceClass_100, PriceClass_200, or PriceClass_All."
  }
}

# -----------------------------------------------------------------------------
# Cache Behavior Tuning Variables
# -----------------------------------------------------------------------------

variable "default_ttl" {
  description = "Default time to live in seconds for cached objects when the origin does not specify Cache-Control or Expires headers. Default is 86400 seconds (1 day), suitable for static assets that change occasionally."
  type        = number
  default     = 86400

  validation {
    condition     = var.default_ttl >= 0 && var.default_ttl <= 31536000
    error_message = "Default TTL must be between 0 and 31536000 seconds (1 year)."
  }
}

variable "max_ttl" {
  description = "Maximum time to live in seconds for cached objects, regardless of Cache-Control headers from origin. Default is 31536000 seconds (1 year), the maximum allowed by CloudFront."
  type        = number
  default     = 31536000

  validation {
    condition     = var.max_ttl >= 0 && var.max_ttl <= 31536000
    error_message = "Maximum TTL must be between 0 and 31536000 seconds (1 year)."
  }
}

variable "min_ttl" {
  description = "Minimum time to live in seconds for cached objects. CloudFront caches objects for at least this duration, even if the origin specifies a shorter duration. Default is 0 to respect origin headers."
  type        = number
  default     = 0

  validation {
    condition     = var.min_ttl >= 0 && var.min_ttl <= 31536000
    error_message = "Minimum TTL must be between 0 and 31536000 seconds (1 year)."
  }
}

# -----------------------------------------------------------------------------
# Custom Error Response Configuration Variables
# -----------------------------------------------------------------------------

variable "error_caching_min_ttl" {
  description = "Minimum TTL in seconds for caching custom error responses. Used for SPA routing where 403/404 errors should return index.html. A low value (10 seconds) allows quick recovery from actual errors while still reducing origin load."
  type        = number
  default     = 10

  validation {
    condition     = var.error_caching_min_ttl >= 0 && var.error_caching_min_ttl <= 31536000
    error_message = "Error caching minimum TTL must be between 0 and 31536000 seconds (1 year)."
  }
}

# -----------------------------------------------------------------------------
# Custom Domain Configuration Variables (Optional)
# -----------------------------------------------------------------------------

variable "aliases" {
  description = "List of CNAMEs (alternate domain names) for the CloudFront distribution. Requires an ACM certificate that covers these domains. Leave empty to use only the CloudFront-provided domain."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for alias in var.aliases : can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", alias))])
    error_message = "Each alias must be a valid domain name."
  }
}

variable "acm_certificate_arn" {
  description = "ARN of ACM certificate in us-east-1 region for HTTPS on custom domains. Required if aliases are specified. Must be a wildcard or explicitly cover all specified aliases. Leave empty when not using custom domains."
  type        = string
  default     = ""

  validation {
    condition     = var.acm_certificate_arn == "" || can(regex("^arn:aws:acm:us-east-1:[0-9]{12}:certificate/[a-f0-9-]+$", var.acm_certificate_arn))
    error_message = "ACM certificate ARN must be empty or a valid ACM certificate ARN in us-east-1 region."
  }
}

# -----------------------------------------------------------------------------
# Index Document Configuration Variables
# -----------------------------------------------------------------------------

variable "index_document" {
  description = "Index document for static website hosting. This file is served when visitors request the root URL or any directory. Default is 'index.html' which is standard for React/Vite applications."
  type        = string
  default     = "index.html"

  validation {
    condition     = length(var.index_document) > 0 && !can(regex("^/", var.index_document))
    error_message = "Index document must not be empty and must not start with a forward slash."
  }
}

variable "default_root_object" {
  description = "The object that CloudFront returns when a viewer requests the root URL (e.g., https://example.com/). This is typically the same as index_document and defaults to 'index.html' for SPA applications."
  type        = string
  default     = "index.html"

  validation {
    condition     = length(var.default_root_object) > 0 && !can(regex("^/", var.default_root_object))
    error_message = "Default root object must not be empty and must not start with a forward slash."
  }
}

variable "error_document" {
  description = "Error document for static website hosting. For single-page applications (SPA), this should be 'index.html' to enable client-side routing - all 404 errors will serve the main application which handles routing internally."
  type        = string
  default     = "index.html"

  validation {
    condition     = length(var.error_document) > 0 && !can(regex("^/", var.error_document))
    error_message = "Error document must not be empty and must not start with a forward slash."
  }
}

# -----------------------------------------------------------------------------
# Resource Tagging Variables
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Tags to apply to all resources created by this module. These tags are merged with module-generated tags (Name, Environment, etc.) and should include standard organizational tags like Project, ManagedBy, and Region."
  type        = map(string)
  default     = {}
}
