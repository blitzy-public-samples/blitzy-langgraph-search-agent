# -----------------------------------------------------------------------------
# IAM Module - Input Variables
# -----------------------------------------------------------------------------
# Variables for configuring IAM roles and policies for ECS and GitHub Actions.
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, production)"
  type        = string
}

variable "github_org" {
  description = "GitHub organization or username for OIDC trust"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name for OIDC trust"
  type        = string
}

variable "github_oidc_thumbprint" {
  description = "GitHub OIDC provider thumbprint"
  type        = string
  default     = "6938fd4d98bab03faadb97b34396831e3780aea1"
}

variable "ecr_repository_arn" {
  description = "ARN of the ECR repository for push/pull permissions"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the frontend S3 bucket for sync permissions"
  type        = string
}

variable "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution for invalidation permissions"
  type        = string
}

variable "ecs_cluster_arn" {
  description = "ARN of the ECS cluster for deployment permissions"
  type        = string
  default     = ""
}

variable "ecs_service_arn" {
  description = "ARN of the ECS service for deployment permissions"
  type        = string
  default     = ""
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table for task role permissions"
  type        = string
}

variable "secrets_arns" {
  description = "List of Secrets Manager secret ARNs for task execution role"
  type        = list(string)
  default     = []
}

variable "log_group_arn" {
  description = "ARN of the CloudWatch log group for logging permissions"
  type        = string
}

variable "tags" {
  description = "Tags to apply to IAM resources"
  type        = map(string)
  default     = {}
}
