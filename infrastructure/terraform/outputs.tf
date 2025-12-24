# -----------------------------------------------------------------------------
# LangGraph Search Agent - Terraform Root Outputs
# -----------------------------------------------------------------------------
# Exports key resource identifiers and URLs for use by:
#   - CI/CD pipelines (backend-deploy.yml, frontend-deploy.yml)
#   - Local development and debugging
#   - Integration with other systems
#
# Sensitive values are marked appropriately to prevent accidental exposure.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# ECR Repository Outputs
# -----------------------------------------------------------------------------
output "ecr_repository_url" {
  description = "URL of the ECR repository for Docker image push/pull"
  value       = module.ecr.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = module.ecr.repository_arn
}

output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = module.ecr.repository_name
}

# -----------------------------------------------------------------------------
# ECS Cluster Outputs
# -----------------------------------------------------------------------------
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs_fargate.cluster_name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.ecs_fargate.cluster_arn
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.ecs_fargate.service_name
}

output "ecs_service_arn" {
  description = "ARN of the ECS service"
  value       = module.ecs_fargate.service_arn
}

output "ecs_task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = module.ecs_fargate.task_definition_arn
}

# -----------------------------------------------------------------------------
# Backend API Outputs
# -----------------------------------------------------------------------------
output "backend_url" {
  description = "URL of the backend API (via ALB)"
  value       = module.ecs_fargate.backend_url
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.ecs_fargate.alb_dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.ecs_fargate.alb_arn
}

output "alb_zone_id" {
  description = "Hosted zone ID of the Application Load Balancer for Route53 alias records"
  value       = module.ecs_fargate.alb_zone_id
}

# -----------------------------------------------------------------------------
# Frontend Hosting Outputs
# -----------------------------------------------------------------------------
output "frontend_bucket_name" {
  description = "Name of the S3 bucket for frontend assets"
  value       = module.frontend.bucket_name
}

output "frontend_bucket_arn" {
  description = "ARN of the S3 bucket for frontend assets"
  value       = module.frontend.bucket_arn
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID for cache invalidation"
  value       = module.frontend.distribution_id
}

output "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = module.frontend.distribution_arn
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name (frontend URL)"
  value       = module.frontend.distribution_domain
}

output "frontend_url" {
  description = "URL of the frontend application"
  value       = "https://${module.frontend.distribution_domain}"
}

# -----------------------------------------------------------------------------
# Networking Outputs
# -----------------------------------------------------------------------------
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

# -----------------------------------------------------------------------------
# IAM Role Outputs
# -----------------------------------------------------------------------------
output "github_actions_role_arn" {
  description = "ARN of the IAM role for GitHub Actions OIDC authentication"
  value       = module.iam.github_actions_role_arn
  sensitive   = true
}

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = module.iam.task_execution_role_arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = module.iam.task_role_arn
}

# -----------------------------------------------------------------------------
# Database Outputs
# -----------------------------------------------------------------------------
output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for conversation persistence"
  value       = module.database.table_name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = module.database.table_arn
}

# -----------------------------------------------------------------------------
# Secrets Manager Outputs
# -----------------------------------------------------------------------------
output "openai_secret_arn" {
  description = "ARN of the OpenAI API key secret"
  value       = module.secrets.openai_secret_arn
  sensitive   = true
}

output "tavily_secret_arn" {
  description = "ARN of the Tavily API key secret"
  value       = module.secrets.tavily_secret_arn
  sensitive   = true
}

output "secrets_arns" {
  description = "Map of all secret ARNs for reference by ECS task definitions"
  value       = module.secrets.secret_arns
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Monitoring Outputs
# -----------------------------------------------------------------------------
output "log_group_name" {
  description = "Name of the CloudWatch log group for ECS containers"
  value       = module.monitoring.log_group_name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = module.monitoring.log_group_arn
}

# -----------------------------------------------------------------------------
# Terraform State Backend Outputs
# -----------------------------------------------------------------------------
output "terraform_state_bucket" {
  description = "Name of the S3 bucket storing Terraform state"
  value       = module.storage.state_bucket_name
}

output "terraform_lock_table" {
  description = "Name of the DynamoDB table for Terraform state locking"
  value       = module.storage.dynamodb_lock_table_name
}

# -----------------------------------------------------------------------------
# Computed Outputs for CI/CD
# -----------------------------------------------------------------------------
output "aws_region" {
  description = "AWS region where resources are deployed"
  value       = var.aws_region
}

output "environment" {
  description = "Deployment environment name"
  value       = var.environment
}
