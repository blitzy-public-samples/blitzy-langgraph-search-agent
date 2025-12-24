# -----------------------------------------------------------------------------
# LangGraph Search Agent - Production Environment Configuration
# -----------------------------------------------------------------------------
# This is the production environment root module that serves as the entry point
# for deploying production-grade infrastructure. It references the parent root
# module and passes production-specific variable values.
#
# Key Characteristics:
# - Isolated Terraform state: state/prod/terraform.tfstate
# - Production sizing: Higher CPU, memory, and scaling limits
# - Multi-AZ NAT Gateway for high availability
# - Full capacity auto-scaling (2-10 tasks)
# - Longer log retention for compliance
#
# Bootstrap Requirements:
# Before first deployment, ensure the following resources exist:
# - S3 bucket: langgraph-search-agent-terraform-state (with versioning enabled)
# - DynamoDB table: langgraph-search-agent-terraform-locks (partition key: LockID)
#
# Usage:
#   cd infrastructure/terraform/environments/prod
#   terraform init
#   terraform plan -var-file=terraform.tfvars
#   terraform apply -var-file=terraform.tfvars
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Terraform Configuration Block
# -----------------------------------------------------------------------------
# Combines backend configuration with version constraints in a single block.
# The S3 backend enables team collaboration with state locking via DynamoDB.
# -----------------------------------------------------------------------------
terraform {
  # Production-specific state backend configuration
  # State is isolated per environment using the key prefix pattern
  backend "s3" {
    bucket         = "langgraph-search-agent-terraform-state"
    key            = "state/prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "langgraph-search-agent-terraform-locks"
  }

  # Terraform and provider version constraints
  # Must match the root module's versions.tf for consistency
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

# -----------------------------------------------------------------------------
# AWS Provider Configuration
# -----------------------------------------------------------------------------
# Configures the AWS provider with the target region and default tags.
# Default tags are automatically applied to all resources for consistency.
# -----------------------------------------------------------------------------
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Region      = var.aws_region
    }
  }
}

# -----------------------------------------------------------------------------
# Root Module Invocation
# -----------------------------------------------------------------------------
# Invokes the parent root module with production-specific variable values.
# All infrastructure resources are created through this single module reference.
# This pattern enables code reuse while maintaining environment isolation.
# -----------------------------------------------------------------------------
module "infrastructure" {
  source = "../../"

  # ---------------------------------------------------------------------------
  # Project Configuration
  # ---------------------------------------------------------------------------
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  tags         = var.tags

  # ---------------------------------------------------------------------------
  # ECR Configuration
  # ---------------------------------------------------------------------------
  ecr_repository_name   = var.ecr_repository_name
  image_retention_count = var.image_retention_count
  ecr_scan_on_push      = var.ecr_scan_on_push

  # ---------------------------------------------------------------------------
  # ECS Configuration (Production Sizing)
  # Production uses higher CPU/memory and larger scaling range
  # ---------------------------------------------------------------------------
  ecs_cluster_name = var.ecs_cluster_name
  ecs_service_name = var.ecs_service_name
  ecs_task_name    = var.ecs_task_name
  container_name   = var.container_name
  container_port   = var.container_port
  cpu              = var.cpu    # 1024 for production
  memory           = var.memory # 2048 for production
  desired_count    = var.desired_count
  min_capacity     = var.min_capacity # 2 for production (high availability)
  max_capacity     = var.max_capacity # 10 for production (scale to handle load)

  # Health check configuration
  health_check_path                = var.health_check_path
  health_check_interval            = var.health_check_interval
  health_check_timeout             = var.health_check_timeout
  health_check_healthy_threshold   = var.health_check_healthy_threshold
  health_check_unhealthy_threshold = var.health_check_unhealthy_threshold

  # ---------------------------------------------------------------------------
  # Auto-Scaling Configuration
  # Production has longer scale-in cooldown for stability
  # ---------------------------------------------------------------------------
  cpu_target_value   = var.cpu_target_value
  scale_out_cooldown = var.scale_out_cooldown
  scale_in_cooldown  = var.scale_in_cooldown

  # ---------------------------------------------------------------------------
  # Frontend Configuration
  # ---------------------------------------------------------------------------
  frontend_bucket_name   = var.frontend_bucket_name
  cloudfront_price_class = var.cloudfront_price_class
  cloudfront_default_ttl = var.cloudfront_default_ttl
  cloudfront_max_ttl     = var.cloudfront_max_ttl
  cloudfront_min_ttl     = var.cloudfront_min_ttl

  # ---------------------------------------------------------------------------
  # Networking Configuration
  # Production uses multi-AZ NAT for high availability
  # ---------------------------------------------------------------------------
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway # false for production (multi-AZ)

  # ---------------------------------------------------------------------------
  # GitHub OIDC Configuration
  # Enables secure CI/CD authentication without long-lived credentials
  # ---------------------------------------------------------------------------
  github_org             = var.github_org
  github_repo            = var.github_repo
  github_oidc_thumbprint = var.github_oidc_thumbprint

  # ---------------------------------------------------------------------------
  # Database Configuration
  # ---------------------------------------------------------------------------
  dynamodb_table_name    = var.dynamodb_table_name
  dynamodb_billing_mode  = var.dynamodb_billing_mode
  dynamodb_ttl_enabled   = var.dynamodb_ttl_enabled
  dynamodb_ttl_attribute = var.dynamodb_ttl_attribute

  # ---------------------------------------------------------------------------
  # Application Configuration
  # ---------------------------------------------------------------------------
  cors_origins = var.cors_origins
  api_url      = var.api_url

  # ---------------------------------------------------------------------------
  # Monitoring Configuration
  # Production uses longer retention for compliance and troubleshooting
  # ---------------------------------------------------------------------------
  log_retention_days        = var.log_retention_days
  enable_container_insights = var.enable_container_insights
  enable_execute_command    = var.enable_execute_command

  # ---------------------------------------------------------------------------
  # Secrets Configuration
  # ---------------------------------------------------------------------------
  create_secrets             = var.create_secrets
  openai_api_key_secret_name = var.openai_api_key_secret_name
  tavily_api_key_secret_name = var.tavily_api_key_secret_name

  # ---------------------------------------------------------------------------
  # Terraform State Backend Configuration
  # ---------------------------------------------------------------------------
  terraform_state_bucket     = var.terraform_state_bucket
  terraform_state_lock_table = var.terraform_state_lock_table
  terraform_state_key        = var.terraform_state_key

  # ---------------------------------------------------------------------------
  # ALB Configuration
  # Production typically uses internet-facing ALB with deletion protection
  # ---------------------------------------------------------------------------
  alb_internal            = var.alb_internal
  alb_idle_timeout        = var.alb_idle_timeout
  alb_deletion_protection = var.alb_deletion_protection
  enable_https            = var.enable_https
  acm_certificate_arn     = var.acm_certificate_arn
  ssl_policy              = var.ssl_policy
}

# -----------------------------------------------------------------------------
# Variable Declarations
# -----------------------------------------------------------------------------
# All variables mirror the root module's variables.tf to enable pass-through.
# Values are populated from terraform.tfvars with production-specific settings.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Project Configuration Variables
# -----------------------------------------------------------------------------
variable "project_name" {
  description = "Name of the project used for resource naming and tagging"
  type        = string
  default     = "langgraph-search-agent"
}

variable "environment" {
  description = "Deployment environment (dev, staging, or production)"
  type        = string
  default     = "production"
}

variable "aws_region" {
  description = "AWS region where all resources will be provisioned"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# ECR Configuration Variables
# -----------------------------------------------------------------------------
variable "ecr_repository_name" {
  description = "Name of the ECR repository for backend Docker images"
  type        = string
  default     = "langgraph-search-agent-backend"
}

variable "image_retention_count" {
  description = "Number of tagged Docker images to retain in ECR"
  type        = number
  default     = 10
}

variable "ecr_scan_on_push" {
  description = "Enable image vulnerability scanning on push"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# ECS Configuration Variables
# -----------------------------------------------------------------------------
variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "langgraph-search-agent-cluster"
}

variable "ecs_service_name" {
  description = "Name of the ECS service"
  type        = string
  default     = "langgraph-search-agent-service"
}

variable "ecs_task_name" {
  description = "Name of the ECS task definition"
  type        = string
  default     = "langgraph-search-agent-task"
}

variable "container_name" {
  description = "Name of the container within the task definition"
  type        = string
  default     = "langgraph-search-agent-container"
}

variable "container_port" {
  description = "Port the backend container listens on"
  type        = number
  default     = 8000
}

variable "cpu" {
  description = "Fargate CPU units (production default: 1024)"
  type        = number
  default     = 1024
}

variable "memory" {
  description = "Fargate memory in MB (production default: 2048)"
  type        = number
  default     = 2048
}

variable "desired_count" {
  description = "Desired number of ECS tasks (production default: 2)"
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Minimum ECS tasks for auto-scaling (production default: 2)"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum ECS tasks for auto-scaling (production default: 10)"
  type        = number
  default     = 10
}

variable "health_check_path" {
  description = "HTTP path for ALB health checks"
  type        = string
  default     = "/health"
}

variable "health_check_interval" {
  description = "Interval between health checks in seconds"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "Consecutive successful health checks to mark healthy"
  type        = number
  default     = 2
}

variable "health_check_unhealthy_threshold" {
  description = "Consecutive failed health checks to mark unhealthy"
  type        = number
  default     = 3
}

# -----------------------------------------------------------------------------
# Auto-Scaling Configuration Variables
# -----------------------------------------------------------------------------
variable "cpu_target_value" {
  description = "Target CPU utilization percentage for auto-scaling"
  type        = number
  default     = 70
}

variable "scale_out_cooldown" {
  description = "Cooldown in seconds after scale-out"
  type        = number
  default     = 60
}

variable "scale_in_cooldown" {
  description = "Cooldown in seconds after scale-in (production: 300)"
  type        = number
  default     = 300
}

# -----------------------------------------------------------------------------
# Frontend Configuration Variables
# -----------------------------------------------------------------------------
variable "frontend_bucket_name" {
  description = "S3 bucket name for frontend static assets"
  type        = string
  default     = "langgraph-search-agent-frontend-production"
}

variable "cloudfront_price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}

variable "cloudfront_default_ttl" {
  description = "Default TTL in seconds for CloudFront cache"
  type        = number
  default     = 86400
}

variable "cloudfront_max_ttl" {
  description = "Maximum TTL in seconds for CloudFront cache"
  type        = number
  default     = 31536000
}

variable "cloudfront_min_ttl" {
  description = "Minimum TTL in seconds for CloudFront cache"
  type        = number
  default     = 0
}

# -----------------------------------------------------------------------------
# Networking Configuration Variables
# -----------------------------------------------------------------------------
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones for multi-AZ deployment"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnet internet access"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use single NAT Gateway (false for production multi-AZ)"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# GitHub OIDC Configuration Variables
# -----------------------------------------------------------------------------
variable "github_org" {
  description = "GitHub organization or username owning the repository"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "github_oidc_thumbprint" {
  description = "GitHub Actions OIDC provider thumbprint"
  type        = string
  default     = "6938fd4d98bab03faadb97b34396831e3780aea1"
}

# -----------------------------------------------------------------------------
# Database Configuration Variables
# -----------------------------------------------------------------------------
variable "dynamodb_table_name" {
  description = "DynamoDB table name for conversation sessions"
  type        = string
  default     = "langgraph-conversations"
}

variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "dynamodb_ttl_enabled" {
  description = "Enable TTL for automatic session expiration"
  type        = bool
  default     = true
}

variable "dynamodb_ttl_attribute" {
  description = "TTL attribute name for DynamoDB"
  type        = string
  default     = "expiration"
}

# -----------------------------------------------------------------------------
# Application Configuration Variables
# -----------------------------------------------------------------------------
variable "cors_origins" {
  description = "Allowed CORS origins for the backend API"
  type        = list(string)
  default     = ["*"]
}

variable "api_url" {
  description = "Base URL for the backend API"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Monitoring Configuration Variables
# -----------------------------------------------------------------------------
variable "log_retention_days" {
  description = "CloudWatch log retention in days (production: 30)"
  type        = number
  default     = 30
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights"
  type        = bool
  default     = true
}

variable "enable_execute_command" {
  description = "Enable ECS Exec for debugging containers"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Secrets Configuration Variables
# -----------------------------------------------------------------------------
variable "create_secrets" {
  description = "Create Secrets Manager secrets for API keys"
  type        = bool
  default     = true
}

variable "openai_api_key_secret_name" {
  description = "Secrets Manager secret name for OpenAI API key"
  type        = string
  default     = "langgraph-search-agent/openai-api-key"
}

variable "tavily_api_key_secret_name" {
  description = "Secrets Manager secret name for Tavily API key"
  type        = string
  default     = "langgraph-search-agent/tavily-api-key"
}

# -----------------------------------------------------------------------------
# Terraform State Backend Configuration Variables
# -----------------------------------------------------------------------------
variable "terraform_state_bucket" {
  description = "S3 bucket name for Terraform state"
  type        = string
  default     = "langgraph-search-agent-terraform-state"
}

variable "terraform_state_lock_table" {
  description = "DynamoDB table name for Terraform state locking"
  type        = string
  default     = "langgraph-search-agent-terraform-locks"
}

variable "terraform_state_key" {
  description = "S3 key path for Terraform state file"
  type        = string
  default     = "state/prod/terraform.tfstate"
}

# -----------------------------------------------------------------------------
# ALB Configuration Variables
# -----------------------------------------------------------------------------
variable "alb_internal" {
  description = "Create internal ALB (false for internet-facing)"
  type        = bool
  default     = false
}

variable "alb_idle_timeout" {
  description = "ALB idle timeout in seconds"
  type        = number
  default     = 60
}

variable "alb_deletion_protection" {
  description = "Enable deletion protection for ALB"
  type        = bool
  default     = false
}

variable "enable_https" {
  description = "Enable HTTPS on ALB (requires ACM certificate)"
  type        = bool
  default     = false
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for HTTPS"
  type        = string
  default     = ""
}

variable "ssl_policy" {
  description = "SSL policy for HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

# -----------------------------------------------------------------------------
# Output Passthrough
# -----------------------------------------------------------------------------
# Re-exports all outputs from the infrastructure module for CI/CD consumption.
# These outputs are used by GitHub Actions workflows for deployment automation.
# -----------------------------------------------------------------------------

# ECR Outputs
output "ecr_repository_url" {
  description = "URL of the ECR repository for Docker image push/pull"
  value       = module.infrastructure.ecr_repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = module.infrastructure.ecr_repository_arn
}

output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = module.infrastructure.ecr_repository_name
}

# ECS Outputs
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.infrastructure.ecs_cluster_name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.infrastructure.ecs_cluster_arn
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.infrastructure.ecs_service_name
}

output "ecs_service_arn" {
  description = "ARN of the ECS service"
  value       = module.infrastructure.ecs_service_arn
}

output "ecs_task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = module.infrastructure.ecs_task_definition_arn
}

# Backend API Outputs
output "backend_url" {
  description = "URL of the backend API (via ALB)"
  value       = module.infrastructure.backend_url
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.infrastructure.alb_dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.infrastructure.alb_arn
}

output "alb_zone_id" {
  description = "Hosted zone ID of the ALB for Route53 alias records"
  value       = module.infrastructure.alb_zone_id
}

# Frontend Outputs
output "frontend_bucket_name" {
  description = "Name of the S3 bucket for frontend assets"
  value       = module.infrastructure.frontend_bucket_name
}

output "frontend_bucket_arn" {
  description = "ARN of the S3 bucket for frontend assets"
  value       = module.infrastructure.frontend_bucket_arn
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID for cache invalidation"
  value       = module.infrastructure.cloudfront_distribution_id
}

output "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = module.infrastructure.cloudfront_distribution_arn
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.infrastructure.cloudfront_domain_name
}

output "frontend_url" {
  description = "URL of the frontend application"
  value       = module.infrastructure.frontend_url
}

# Networking Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.infrastructure.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.infrastructure.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.infrastructure.private_subnet_ids
}

# IAM Outputs
output "github_actions_role_arn" {
  description = "ARN of the IAM role for GitHub Actions OIDC"
  value       = module.infrastructure.github_actions_role_arn
  sensitive   = true
}

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = module.infrastructure.ecs_task_execution_role_arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = module.infrastructure.ecs_task_role_arn
}

# Database Outputs
output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = module.infrastructure.dynamodb_table_name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = module.infrastructure.dynamodb_table_arn
}

# Secrets Outputs
output "openai_secret_arn" {
  description = "ARN of the OpenAI API key secret"
  value       = module.infrastructure.openai_secret_arn
  sensitive   = true
}

output "tavily_secret_arn" {
  description = "ARN of the Tavily API key secret"
  value       = module.infrastructure.tavily_secret_arn
  sensitive   = true
}

output "secrets_arns" {
  description = "Map of all secret ARNs"
  value       = module.infrastructure.secrets_arns
  sensitive   = true
}

# Monitoring Outputs
output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = module.infrastructure.log_group_name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = module.infrastructure.log_group_arn
}

# Terraform State Outputs
output "terraform_state_bucket" {
  description = "Name of the S3 bucket storing Terraform state"
  value       = module.infrastructure.terraform_state_bucket
}

output "terraform_lock_table" {
  description = "Name of the DynamoDB table for Terraform state locking"
  value       = module.infrastructure.terraform_lock_table
}

# Environment Outputs
output "aws_region" {
  description = "AWS region where resources are deployed"
  value       = module.infrastructure.aws_region
}

output "environment" {
  description = "Deployment environment name"
  value       = module.infrastructure.environment
}
