# -----------------------------------------------------------------------------
# Frontend Module - Main Configuration
# -----------------------------------------------------------------------------
# Creates the frontend hosting infrastructure for the LangGraph Search Agent:
# - S3 bucket for static assets (React/Vite build output)
# - CloudFront distribution for global content delivery
# - Origin Access Identity (OAI) for secure S3 access
# - Bucket policy restricting access to CloudFront only
# - Server-side encryption for data at rest
# - Versioning for deployment rollback capability
#
# SPA Optimizations:
# - Custom error responses route 403/404 to index.html for client-side routing
# - HTTPS redirect for secure connections
# - Compression enabled for faster delivery
# - Optimized cache TTLs for static assets
#
# Integration:
# - Exports distribution_id for frontend-deploy.yml CloudFront invalidation
# - Exports bucket_name for frontend-deploy.yml S3 sync operations
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Local Values
# -----------------------------------------------------------------------------
# Computed values and merged tags used throughout the module
# -----------------------------------------------------------------------------

locals {
  # Merge module-specific tags with user-provided tags
  default_tags = {
    Module = "frontend"
  }
  merged_tags = merge(local.default_tags, var.tags)

  # Unique origin ID for CloudFront to reference the S3 bucket
  s3_origin_id = "S3-${var.bucket_name}"
}

# -----------------------------------------------------------------------------
# S3 Bucket for Static Assets
# -----------------------------------------------------------------------------
# Primary storage for React/Vite frontend build output (dist/ directory)
# Naming convention: langgraph-search-agent-frontend-{environment}
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "frontend" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = merge(local.merged_tags, {
    Name        = var.bucket_name
    Description = "Static frontend assets for ${var.project_name}"
  })
}

# -----------------------------------------------------------------------------
# S3 Bucket Versioning
# -----------------------------------------------------------------------------
# Enables object versioning for deployment rollback capability
# Previous versions can be restored in case of problematic deployments
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  versioning_configuration {
    status = "Enabled"
  }
}

# -----------------------------------------------------------------------------
# S3 Bucket Server-Side Encryption
# -----------------------------------------------------------------------------
# Encrypts all objects at rest using AES-256 (S3-managed keys)
# Ensures compliance with data protection requirements
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

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
# Blocks ALL public access to the bucket
# Only CloudFront can access objects through the Origin Access Identity
# This is a critical security measure to prevent direct S3 access
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# S3 Bucket Website Configuration
# -----------------------------------------------------------------------------
# Configures the bucket for static website hosting
# SPA routing: both index and error documents point to index.html
# This ensures client-side routing works correctly for all paths
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = var.index_document
  }

  error_document {
    key = var.error_document
  }
}

# -----------------------------------------------------------------------------
# CloudFront Origin Access Identity (OAI)
# -----------------------------------------------------------------------------
# Creates a special CloudFront identity for accessing private S3 content
# This allows CloudFront to serve content from the S3 bucket while
# keeping the bucket private (not publicly accessible)
# -----------------------------------------------------------------------------

resource "aws_cloudfront_origin_access_identity" "frontend" {
  comment = "OAI for ${var.bucket_name}"
}

# -----------------------------------------------------------------------------
# S3 Bucket Policy - CloudFront Access Only
# -----------------------------------------------------------------------------
# Grants read access ONLY to the CloudFront Origin Access Identity
# Ensures the bucket is never directly accessible from the internet
# Policy follows AWS IAM best practices with explicit principal specification
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontOAI"
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.frontend.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })

  # Ensure public access block is applied before setting the policy
  depends_on = [aws_s3_bucket_public_access_block.frontend]
}

# -----------------------------------------------------------------------------
# CloudFront Distribution
# -----------------------------------------------------------------------------
# Global content delivery network for the frontend application
# Features:
# - HTTPS redirect for all requests
# - Compression for faster delivery
# - SPA routing via custom error responses
# - Optimized caching for static assets
# -----------------------------------------------------------------------------

resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CDN for ${var.project_name} frontend"
  default_root_object = var.default_root_object
  price_class         = var.price_class

  # Custom domain aliases (optional)
  aliases = length(var.aliases) > 0 ? var.aliases : null

  # ---------------------------------------------------------------------------
  # Origin Configuration
  # ---------------------------------------------------------------------------
  # S3 bucket as the origin with OAI authentication
  # Uses regional domain name for consistent behavior
  # ---------------------------------------------------------------------------

  origin {
    domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.frontend.cloudfront_access_identity_path
    }
  }

  # ---------------------------------------------------------------------------
  # Default Cache Behavior
  # ---------------------------------------------------------------------------
  # Handles all requests to the distribution
  # - Allows GET, HEAD, OPTIONS methods
  # - Caches GET and HEAD responses
  # - Redirects HTTP to HTTPS
  # - Compresses content for faster delivery
  # ---------------------------------------------------------------------------

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    # Cache TTL settings
    min_ttl     = var.min_ttl
    default_ttl = var.default_ttl
    max_ttl     = var.max_ttl
  }

  # ---------------------------------------------------------------------------
  # Custom Error Responses - SPA Routing
  # ---------------------------------------------------------------------------
  # Routes 403 (access denied) and 404 (not found) to index.html
  # This enables client-side routing in single-page applications
  # The React Router handles navigation without server-side routing
  # error_caching_min_ttl is set low to allow quick recovery from actual errors
  # ---------------------------------------------------------------------------

  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = var.error_caching_min_ttl
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = var.error_caching_min_ttl
  }

  # ---------------------------------------------------------------------------
  # Geographic Restrictions
  # ---------------------------------------------------------------------------
  # No geographic restrictions - content available worldwide
  # Can be modified to restrict access to specific countries if needed
  # ---------------------------------------------------------------------------

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # ---------------------------------------------------------------------------
  # SSL/TLS Certificate Configuration
  # ---------------------------------------------------------------------------
  # Uses CloudFront default certificate when no custom domain is specified
  # For custom domains, uses the provided ACM certificate from us-east-1
  # ---------------------------------------------------------------------------

  viewer_certificate {
    cloudfront_default_certificate = length(var.aliases) == 0 || var.acm_certificate_arn == ""
    acm_certificate_arn            = var.acm_certificate_arn != "" ? var.acm_certificate_arn : null
    ssl_support_method             = var.acm_certificate_arn != "" ? "sni-only" : null
    minimum_protocol_version       = var.acm_certificate_arn != "" ? "TLSv1.2_2021" : null
  }

  # ---------------------------------------------------------------------------
  # Resource Tags
  # ---------------------------------------------------------------------------

  tags = merge(local.merged_tags, {
    Name        = "${var.project_name}-distribution"
    Description = "CloudFront distribution for ${var.project_name} frontend"
  })

  # Ensure bucket versioning and encryption are configured before distribution
  depends_on = [
    aws_s3_bucket_versioning.frontend,
    aws_s3_bucket_server_side_encryption_configuration.frontend
  ]
}
