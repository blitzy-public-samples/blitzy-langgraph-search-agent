#------------------------------------------------------------------------------
# LangGraph Search Agent - Staging Environment Configuration
#------------------------------------------------------------------------------
# This is the staging environment configuration for pre-production testing
# and validation before production deployment.
#
# Purpose:
#   - Pre-production validation of infrastructure changes
#   - Integration testing with production-like settings
#   - Cost-effective staging with medium resource sizing
#
# State Isolation:
#   - Uses separate S3 state path: state/staging/terraform.tfstate
#   - Enables independent deployment from dev and production environments
#   - Prevents state file conflicts during parallel deployments
#
# Resource Sizing (Section 0.7.3):
#   - CPU: 512 (medium sizing for validation)
#   - Memory: 1024 MB (medium sizing for validation)
#   - Desired Count: 1 (cost-effective staging)
#   - Auto-scaling: 1-3 tasks
#   - Single-AZ NAT Gateway (cost savings)
#
# Bootstrap Requirements:
#   Before first deployment, ensure the S3 state bucket and DynamoDB lock
#   table exist. See infrastructure/terraform/README.md for instructions.
#
# Usage:
#   cd infrastructure/terraform/environments/staging
#   terraform init
#   terraform plan
#   terraform apply
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Terraform Configuration Block
#------------------------------------------------------------------------------
# Combines version constraints and S3 backend configuration
# Backend key is staging-specific for state isolation
#------------------------------------------------------------------------------
terraform {
  # Terraform version constraint - minimum stable version with modern features
  required_version = ">= 1.5.0"

  # Provider version constraints
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

  # S3 Backend Configuration for Staging Environment
  # State is isolated using the staging-specific key path
  backend "s3" {
    bucket         = "langgraph-search-agent-terraform-state"
    key            = "state/staging/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "langgraph-search-agent-terraform-locks"
  }
}

#------------------------------------------------------------------------------
# AWS Provider Configuration
#------------------------------------------------------------------------------
# Configures the AWS provider with region and default tags
# Default tags are applied to all resources for consistent tagging
#------------------------------------------------------------------------------
provider "aws" {
  region = var.aws_region

  # Default tags applied to all resources created by this provider
  # Ensures consistent tagging across all staging infrastructure
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

#------------------------------------------------------------------------------
# Root Module Reference
#------------------------------------------------------------------------------
# Invokes the root module with staging-specific variable values
# All infrastructure is provisioned through this single module reference
# 
# The root module orchestrates:
#   - ECR repository for container images
#   - VPC networking (subnets, security groups, NAT gateway)
#   - ECS Fargate cluster, service, and task definition
#   - Application Load Balancer
#   - S3 bucket and CloudFront distribution for frontend
#   - DynamoDB table for conversation persistence
#   - IAM roles for ECS and GitHub Actions OIDC
#   - Secrets Manager for API keys
#   - CloudWatch logging
#------------------------------------------------------------------------------
module "infrastructure" {
  source = "../../"

  #----------------------------------------------------------------------------
  # Project Configuration
  #----------------------------------------------------------------------------
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  #----------------------------------------------------------------------------
  # ECR Configuration
  #----------------------------------------------------------------------------
  ecr_repository_name   = var.ecr_repository_name
  image_retention_count = var.image_retention_count
  ecr_scan_on_push      = var.ecr_scan_on_push

  #----------------------------------------------------------------------------
  # ECS Cluster and Service Configuration
  #----------------------------------------------------------------------------
  ecs_cluster_name = var.ecs_cluster_name
  ecs_service_name = var.ecs_service_name
  ecs_task_name    = var.ecs_task_name

  #----------------------------------------------------------------------------
  # Container Configuration
  # Staging uses medium sizing (512 CPU, 1024 memory) for cost-effective
  # validation testing while maintaining production-like behavior
  #----------------------------------------------------------------------------
  container_name = var.container_name
  container_port = var.container_port
  cpu            = var.cpu
  memory         = var.memory

  #----------------------------------------------------------------------------
  # Service Scaling Configuration
  # Staging uses minimal scaling (1-3 tasks) for cost efficiency
  #----------------------------------------------------------------------------
  desired_count = var.desired_count
  min_capacity  = var.min_capacity
  max_capacity  = var.max_capacity

  #----------------------------------------------------------------------------
  # Health Check Configuration
  #----------------------------------------------------------------------------
  health_check_path              = var.health_check_path
  health_check_interval          = var.health_check_interval
  health_check_timeout           = var.health_check_timeout
  health_check_healthy_threshold = var.health_check_healthy_threshold
  health_check_unhealthy_threshold = var.health_check_unhealthy_threshold

  #----------------------------------------------------------------------------
  # Auto-Scaling Configuration
  #----------------------------------------------------------------------------
  cpu_target_value   = var.cpu_target_value
  scale_out_cooldown = var.scale_out_cooldown
  scale_in_cooldown  = var.scale_in_cooldown

  #----------------------------------------------------------------------------
  # Frontend Configuration
  #----------------------------------------------------------------------------
  frontend_bucket_name   = var.frontend_bucket_name
  cloudfront_price_class = var.cloudfront_price_class
  cloudfront_default_ttl = var.cloudfront_default_ttl
  cloudfront_max_ttl     = var.cloudfront_max_ttl
  cloudfront_min_ttl     = var.cloudfront_min_ttl

  #----------------------------------------------------------------------------
  # Networking Configuration
  # Uses standard VPC CIDR with 2 availability zones for staging
  #----------------------------------------------------------------------------
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway

  #----------------------------------------------------------------------------
  # GitHub OIDC Configuration
  # Required for passwordless CI/CD authentication
  #----------------------------------------------------------------------------
  github_org             = var.github_org
  github_repo            = var.github_repo
  github_oidc_thumbprint = var.github_oidc_thumbprint

  #----------------------------------------------------------------------------
  # Database Configuration
  #----------------------------------------------------------------------------
  dynamodb_table_name   = var.dynamodb_table_name
  dynamodb_billing_mode = var.dynamodb_billing_mode
  dynamodb_ttl_enabled  = var.dynamodb_ttl_enabled
  dynamodb_ttl_attribute = var.dynamodb_ttl_attribute

  #----------------------------------------------------------------------------
  # Application Configuration
  #----------------------------------------------------------------------------
  cors_origins = var.cors_origins
  api_url      = var.api_url

  #----------------------------------------------------------------------------
  # Monitoring Configuration
  #----------------------------------------------------------------------------
  log_retention_days       = var.log_retention_days
  enable_container_insights = var.enable_container_insights
  enable_execute_command   = var.enable_execute_command

  #----------------------------------------------------------------------------
  # Secrets Configuration
  #----------------------------------------------------------------------------
  create_secrets             = var.create_secrets
  openai_api_key_secret_name = var.openai_api_key_secret_name
  tavily_api_key_secret_name = var.tavily_api_key_secret_name

  #----------------------------------------------------------------------------
  # Terraform State Backend Configuration
  #----------------------------------------------------------------------------
  terraform_state_bucket     = var.terraform_state_bucket
  terraform_state_lock_table = var.terraform_state_lock_table
  terraform_state_key        = var.terraform_state_key

  #----------------------------------------------------------------------------
  # ALB Configuration
  #----------------------------------------------------------------------------
  alb_internal     = var.alb_internal
  alb_idle_timeout = var.alb_idle_timeout

  #----------------------------------------------------------------------------
  # Additional Tags
  #----------------------------------------------------------------------------
  tags = var.tags
}

#------------------------------------------------------------------------------
# Variable Declarations
#------------------------------------------------------------------------------
# All variables mirror the root module variables.tf to support environment
# customization via terraform.tfvars. Variables are populated from the
# staging terraform.tfvars file with staging-specific values.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Project Configuration Variables
#------------------------------------------------------------------------------
variable "project_name" {
  description = "Name of the project used for resource naming and tagging"
  type        = string
  default     = "langgraph-search-agent"
}

variable "environment" {
  description = "Deployment environment (dev, staging, or production)"
  type        = string
  default     = "staging"
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

#------------------------------------------------------------------------------
# ECR Configuration Variables
#------------------------------------------------------------------------------
variable "ecr_repository_name" {
  description = "Name of the ECR repository for storing backend Docker images"
  type        = string
  default     = "langgraph-search-agent-backend"
}

variable "image_retention_count" {
  description = "Number of tagged Docker images to retain in ECR"
  type        = number
  default     = 10
}

variable "ecr_scan_on_push" {
  description = "Enable image vulnerability scanning on push to ECR"
  type        = bool
  default     = true
}

#------------------------------------------------------------------------------
# ECS Configuration Variables
#------------------------------------------------------------------------------
variable "ecs_cluster_name" {
  description = "Name of the ECS cluster for running Fargate tasks"
  type        = string
  default     = "langgraph-search-agent-cluster"
}

variable "ecs_service_name" {
  description = "Name of the ECS service managing the Fargate tasks"
  type        = string
  default     = "langgraph-search-agent-service"
}

variable "ecs_task_name" {
  description = "Name of the ECS task definition for the backend container"
  type        = string
  default     = "langgraph-search-agent-task"
}

variable "container_name" {
  description = "Name of the container within the ECS task definition"
  type        = string
  default     = "langgraph-search-agent-container"
}

variable "container_port" {
  description = "Port number the backend container listens on"
  type        = number
  default     = 8000
}

variable "cpu" {
  description = "Fargate CPU units for the task (512 for staging - medium sizing)"
  type        = number
  default     = 512
}

variable "memory" {
  description = "Fargate memory in MB for the task (1024 for staging - medium sizing)"
  type        = number
  default     = 1024
}

variable "desired_count" {
  description = "Desired number of ECS tasks to run"
  type        = number
  default     = 1
}

variable "min_capacity" {
  description = "Minimum number of ECS tasks for auto-scaling"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of ECS tasks for auto-scaling"
  type        = number
  default     = 3
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
  description = "Number of consecutive successful health checks required"
  type        = number
  default     = 2
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive failed health checks required"
  type        = number
  default     = 3
}

#------------------------------------------------------------------------------
# Auto-Scaling Configuration Variables
#------------------------------------------------------------------------------
variable "cpu_target_value" {
  description = "Target CPU utilization percentage for auto-scaling"
  type        = number
  default     = 70
}

variable "scale_out_cooldown" {
  description = "Cooldown period in seconds after scale-out activity"
  type        = number
  default     = 60
}

variable "scale_in_cooldown" {
  description = "Cooldown period in seconds after scale-in activity"
  type        = number
  default     = 120
}

#------------------------------------------------------------------------------
# Frontend Configuration Variables
#------------------------------------------------------------------------------
variable "frontend_bucket_name" {
  description = "Name of the S3 bucket for hosting frontend static assets"
  type        = string
  default     = "langgraph-search-agent-frontend-staging"
}

variable "cloudfront_price_class" {
  description = "CloudFront price class determining edge location distribution"
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

#------------------------------------------------------------------------------
# Networking Configuration Variables
#------------------------------------------------------------------------------
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
  description = "Use a single NAT Gateway for all AZs (cost savings for staging)"
  type        = bool
  default     = true
}

#------------------------------------------------------------------------------
# GitHub OIDC Configuration Variables
#------------------------------------------------------------------------------
variable "github_org" {
  description = "GitHub organization or username owning the repository"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name for OIDC trust relationship"
  type        = string
}

variable "github_oidc_thumbprint" {
  description = "GitHub Actions OIDC provider thumbprint"
  type        = string
  default     = "6938fd4d98bab03faadb97b34396831e3780aea1"
}

#------------------------------------------------------------------------------
# Database Configuration Variables
#------------------------------------------------------------------------------
variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table for storing conversation sessions"
  type        = string
  default     = "langgraph-conversations-staging"
}

variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode (PAY_PER_REQUEST for on-demand scaling)"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "dynamodb_ttl_enabled" {
  description = "Enable TTL for automatic expiration of old sessions"
  type        = bool
  default     = true
}

variable "dynamodb_ttl_attribute" {
  description = "Name of the TTL attribute for DynamoDB"
  type        = string
  default     = "expiration"
}

#------------------------------------------------------------------------------
# Application Configuration Variables
#------------------------------------------------------------------------------
variable "cors_origins" {
  description = "List of allowed CORS origins for the backend API"
  type        = list(string)
  default     = ["*"]
}

variable "api_url" {
  description = "Base URL for the backend API"
  type        = string
  default     = ""
}

#------------------------------------------------------------------------------
# Monitoring Configuration Variables
#------------------------------------------------------------------------------
variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights for detailed ECS monitoring"
  type        = bool
  default     = false
}

variable "enable_execute_command" {
  description = "Enable ECS Exec for debugging containers"
  type        = bool
  default     = true
}

#------------------------------------------------------------------------------
# Secrets Configuration Variables
#------------------------------------------------------------------------------
variable "create_secrets" {
  description = "Create Secrets Manager secrets for API keys"
  type        = bool
  default     = true
}

variable "openai_api_key_secret_name" {
  description = "Name of the Secrets Manager secret for OpenAI API key"
  type        = string
  default     = "langgraph-search-agent/staging/openai-api-key"
}

variable "tavily_api_key_secret_name" {
  description = "Name of the Secrets Manager secret for Tavily API key"
  type        = string
  default     = "langgraph-search-agent/staging/tavily-api-key"
}

#------------------------------------------------------------------------------
# Terraform State Backend Configuration Variables
#------------------------------------------------------------------------------
variable "terraform_state_bucket" {
  description = "S3 bucket name for storing Terraform state files"
  type        = string
  default     = "langgraph-search-agent-terraform-state"
}

variable "terraform_state_lock_table" {
  description = "DynamoDB table name for Terraform state locking"
  type        = string
  default     = "langgraph-search-agent-terraform-locks"
}

variable "terraform_state_key" {
  description = "S3 key path for the Terraform state file"
  type        = string
  default     = "state/staging/terraform.tfstate"
}

#------------------------------------------------------------------------------
# ALB Configuration Variables
#------------------------------------------------------------------------------
variable "alb_internal" {
  description = "Create an internal ALB (not accessible from internet)"
  type        = bool
  default     = false
}

variable "alb_idle_timeout" {
  description = "ALB connection idle timeout in seconds"
  type        = number
  default     = 60
}

#------------------------------------------------------------------------------
# Output Passthrough
#------------------------------------------------------------------------------
# Re-exports all outputs from the infrastructure module for CI/CD consumption
# These outputs are used by GitHub Actions workflows for deployment
#------------------------------------------------------------------------------

# ECR Repository Outputs
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

# ECS Cluster Outputs
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

# Frontend Hosting Outputs
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
  description = "CloudFront distribution domain name (frontend URL)"
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

# IAM Role Outputs
output "github_actions_role_arn" {
  description = "ARN of the IAM role for GitHub Actions OIDC authentication"
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
  description = "Name of the DynamoDB table for conversation persistence"
  value       = module.infrastructure.dynamodb_table_name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = module.infrastructure.dynamodb_table_arn
}

# Secrets Manager Outputs
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
  description = "Map of all secret ARNs for reference by ECS task definitions"
  value       = module.infrastructure.secrets_arns
  sensitive   = true
}

# Monitoring Outputs
output "log_group_name" {
  description = "Name of the CloudWatch log group for ECS containers"
  value       = module.infrastructure.log_group_name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = module.infrastructure.log_group_arn
}

# Terraform State Backend Outputs
output "terraform_state_bucket" {
  description = "Name of the S3 bucket storing Terraform state"
  value       = module.infrastructure.terraform_state_bucket
}

output "terraform_lock_table" {
  description = "Name of the DynamoDB table for Terraform state locking"
  value       = module.infrastructure.terraform_lock_table
}

# Computed Outputs for CI/CD
output "aws_region" {
  description = "AWS region where resources are deployed"
  value       = module.infrastructure.aws_region
}

output "environment" {
  description = "Deployment environment name"
  value       = module.infrastructure.environment
}
