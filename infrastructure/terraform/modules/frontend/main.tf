# -----------------------------------------------------------------------------
# Frontend Module - Main Configuration
# -----------------------------------------------------------------------------
# Creates the frontend hosting infrastructure:
# - S3 bucket for static assets (React/Vite build output)
# - CloudFront distribution for global content delivery
# - Origin Access Identity (OAI) for secure S3 access
# - Bucket policy restricting access to CloudFront only
#
# SPA Optimizations:
# - Custom error responses route 404s to index.html
# - HTTPS redirect for secure connections
# - Compression enabled for faster delivery
# -----------------------------------------------------------------------------

locals {
  default_tags = {
    Module = "frontend"
  }
  merged_tags  = merge(local.default_tags, var.tags)
  s3_origin_id = "${var.project_name}-s3-origin"
}

# -----------------------------------------------------------------------------
# S3 Bucket for Static Assets
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "frontend" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = merge(local.merged_tags, {
    Name = var.bucket_name
  })
}

# -----------------------------------------------------------------------------
# S3 Bucket Public Access Block
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# CloudFront Origin Access Identity
# -----------------------------------------------------------------------------
resource "aws_cloudfront_origin_access_identity" "frontend" {
  comment = "OAI for ${var.bucket_name}"
}

# -----------------------------------------------------------------------------
# S3 Bucket Policy - CloudFront Access Only
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudFrontReadAccess"
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.frontend.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.frontend]
}

# -----------------------------------------------------------------------------
# CloudFront Distribution
# -----------------------------------------------------------------------------
resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project_name} frontend distribution"
  default_root_object = var.default_root_object
  price_class         = var.price_class

  origin {
    domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.frontend.cloudfront_access_identity_path
    }
  }

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
    min_ttl                = var.min_ttl
    default_ttl            = var.default_ttl
    max_ttl                = var.max_ttl
    compress               = true
  }

  # SPA routing - route 403 and 404 to index.html
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = merge(local.merged_tags, {
    Name = "${var.project_name}-distribution"
  })
}
