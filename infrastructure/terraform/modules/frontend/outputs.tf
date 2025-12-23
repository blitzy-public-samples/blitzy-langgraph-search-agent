# -----------------------------------------------------------------------------
# Frontend Module - Output Values
# -----------------------------------------------------------------------------
# Exports frontend resource identifiers for CI/CD workflows and IAM policies.
# -----------------------------------------------------------------------------

output "bucket_name" {
  description = "Name of the S3 bucket for frontend assets"
  value       = aws_s3_bucket.frontend.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket for frontend assets"
  value       = aws_s3_bucket.frontend.arn
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket"
  value       = aws_s3_bucket.frontend.bucket_regional_domain_name
}

output "distribution_id" {
  description = "CloudFront distribution ID for cache invalidation"
  value       = aws_cloudfront_distribution.frontend.id
}

output "distribution_arn" {
  description = "CloudFront distribution ARN for IAM policies"
  value       = aws_cloudfront_distribution.frontend.arn
}

output "distribution_domain" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.frontend.domain_name
}

output "distribution_hosted_zone_id" {
  description = "CloudFront distribution hosted zone ID for Route53"
  value       = aws_cloudfront_distribution.frontend.hosted_zone_id
}

output "oai_iam_arn" {
  description = "IAM ARN of the Origin Access Identity"
  value       = aws_cloudfront_origin_access_identity.frontend.iam_arn
}
