# -----------------------------------------------------------------------------
# ECR Module - Output Values
# -----------------------------------------------------------------------------
# Exports repository identifiers for use by other modules and CI/CD workflows.
# -----------------------------------------------------------------------------

output "repository_url" {
  description = "The URL of the ECR repository for Docker push operations"
  value       = aws_ecr_repository.main.repository_url
}

output "repository_arn" {
  description = "The ARN of the ECR repository for IAM policies"
  value       = aws_ecr_repository.main.arn
}

output "repository_name" {
  description = "The name of the ECR repository"
  value       = aws_ecr_repository.main.name
}

output "registry_id" {
  description = "The registry ID (AWS account ID) where the repository is created"
  value       = aws_ecr_repository.main.registry_id
}
