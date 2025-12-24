# =============================================================================
# Development Environment - Terraform Configuration
# =============================================================================
# This is the development environment configuration for the LangGraph Search
# Agent infrastructure. It provides isolated, cost-effective infrastructure
# for local testing and feature development.
#
# Key characteristics:
# - Minimal resource sizing (256 CPU, 512MB memory) for cost efficiency
# - Isolated state via S3 key prefix (state/dev/terraform.tfstate)
# - Single-AZ NAT gateway for reduced costs
# - Shorter log retention (7 days) for development
# - Auto-scaling range of 1-2 tasks
#
# Usage:
#   cd infrastructure/terraform/environments/dev
#   terraform init
#   terraform plan -var-file="terraform.tfvars"
#   terraform apply -var-file="terraform.tfvars"
#
# Bootstrap Requirements:
# Before first deployment, ensure the S3 bucket and DynamoDB table exist:
#   aws s3 mb s3://langgraph-search-agent-terraform-state --region us-east-1
#   aws dynamodb create-table \
#     --table-name langgraph-search-agent-terraform-locks \
#     --attribute-definitions AttributeName=LockID,AttributeType=S \
#     --key-schema AttributeName=LockID,KeyType=HASH \
#     --billing-mode PAY_PER_REQUEST \
#     --region us-east-1
# =============================================================================

# -----------------------------------------------------------------------------
# Terraform Configuration Block
# -----------------------------------------------------------------------------
# Combines version constraints, required providers, and backend configuration
# in a single terraform block as required by Terraform syntax.
# -----------------------------------------------------------------------------
terraform {
  # Minimum Terraform version requirement
  # 1.5.0+ provides import blocks, check blocks, and modern HCL features
  required_version = ">= 1.5.0"

  # Required provider configurations
  required_providers {
    # AWS Provider - Latest stable major version with full ECS Fargate support
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    # Random Provider - Used for unique resource naming (bucket suffixes, etc.)
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  # S3 Backend Configuration for Remote State Management
  # Development environment uses isolated state key for multi-environment support
  backend "s3" {
    bucket         = "langgraph-search-agent-terraform-state"
    key            = "state/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "langgraph-search-agent-terraform-locks"
  }
}

# -----------------------------------------------------------------------------
# AWS Provider Configuration
# -----------------------------------------------------------------------------
# Configures the AWS provider with default tags applied to all resources.
# Uses variable-based configuration for flexibility across environments.
# -----------------------------------------------------------------------------
provider "aws" {
  region = var.aws_region

  # Default tags applied to all resources created by this configuration
  # These tags ensure consistent resource identification and cost allocation
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# =============================================================================
# Variable Declarations
# =============================================================================
# These variables mirror the root module's variables.tf to allow passing
# environment-specific values from terraform.tfvars
# =============================================================================

# -----------------------------------------------------------------------------
# Project Configuration Variables
# -----------------------------------------------------------------------------
variable "project_name" {
  description = "Name of the project used for resource naming and tagging"
  type        = string
  default     = "langgraph-search-agent"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.project_name))
    error_message = "Project name must start with a letter and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "aws_region" {
  description = "AWS region for all resources (constrained to us-east-1)"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = var.aws_region == "us-east-1"
    error_message = "AWS region must be us-east-1 as per project constraints."
  }
}

# -----------------------------------------------------------------------------
# ECR Configuration Variables
# -----------------------------------------------------------------------------
variable "ecr_repository_name" {
  description = "Name of the ECR repository for container images"
  type        = string
  default     = "langgraph-search-agent-backend"
}

variable "image_retention_count" {
  description = "Number of container images to retain in ECR lifecycle policy"
  type        = number
  default     = 10

  validation {
    condition     = var.image_retention_count >= 1 && var.image_retention_count <= 100
    error_message = "Image retention count must be between 1 and 100."
  }
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
  description = "Name of the container within the ECS task"
  type        = string
  default     = "langgraph-search-agent-container"
}

variable "container_port" {
  description = "Port exposed by the container (FastAPI application)"
  type        = number
  default     = 8000

  validation {
    condition     = var.container_port > 0 && var.container_port < 65536
    error_message = "Container port must be a valid port number (1-65535)."
  }
}

variable "cpu" {
  description = "Fargate CPU units (256 = 0.25 vCPU, 512 = 0.5 vCPU, etc.)"
  type        = number
  default     = 256

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.cpu)
    error_message = "CPU must be a valid Fargate CPU value: 256, 512, 1024, 2048, or 4096."
  }
}

variable "memory" {
  description = "Fargate memory in MB"
  type        = number
  default     = 512

  validation {
    condition     = var.memory >= 512 && var.memory <= 30720
    error_message = "Memory must be between 512 MB and 30720 MB."
  }
}

variable "desired_count" {
  description = "Desired number of ECS tasks to run"
  type        = number
  default     = 1

  validation {
    condition     = var.desired_count >= 0
    error_message = "Desired count must be a non-negative number."
  }
}

variable "min_capacity" {
  description = "Minimum number of ECS tasks for auto-scaling"
  type        = number
  default     = 1

  validation {
    condition     = var.min_capacity >= 1
    error_message = "Minimum capacity must be at least 1."
  }
}

variable "max_capacity" {
  description = "Maximum number of ECS tasks for auto-scaling"
  type        = number
  default     = 2

  validation {
    condition     = var.max_capacity >= 1
    error_message = "Maximum capacity must be at least 1."
  }
}

variable "health_check_path" {
  description = "Health check endpoint path for ALB target group"
  type        = string
  default     = "/health"
}

# -----------------------------------------------------------------------------
# Frontend Configuration Variables
# -----------------------------------------------------------------------------
variable "frontend_bucket_name" {
  description = "Name of the S3 bucket for frontend static assets"
  type        = string
  default     = "langgraph-search-agent-frontend-dev"
}

# -----------------------------------------------------------------------------
# Networking Configuration Variables
# -----------------------------------------------------------------------------
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "List of availability zones for subnet deployment"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones are required for high availability."
  }
}

# -----------------------------------------------------------------------------
# GitHub OIDC Configuration Variables
# -----------------------------------------------------------------------------
variable "github_org" {
  description = "GitHub organization or username for OIDC trust policy"
  type        = string

  validation {
    condition     = length(var.github_org) > 0
    error_message = "GitHub organization must be specified."
  }
}

variable "github_repo" {
  description = "GitHub repository name for OIDC trust policy"
  type        = string

  validation {
    condition     = length(var.github_repo) > 0
    error_message = "GitHub repository must be specified."
  }
}

# -----------------------------------------------------------------------------
# Database Configuration Variables
# -----------------------------------------------------------------------------
variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table for conversation persistence"
  type        = string
  default     = "langgraph-conversations-dev"
}

# -----------------------------------------------------------------------------
# Monitoring Configuration Variables
# -----------------------------------------------------------------------------
variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 7

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention must be a valid CloudWatch retention value."
  }
}

# -----------------------------------------------------------------------------
# Application Configuration Variables
# -----------------------------------------------------------------------------
variable "cors_origins" {
  description = "List of allowed CORS origins for the backend API"
  type        = list(string)
  default     = ["*"]
}

# =============================================================================
# Root Module Invocation
# =============================================================================
# Invokes the parent root module with development-specific variable values.
# The root module at ../../ orchestrates all child modules (ECR, networking,
# ECS-Fargate, frontend, IAM, secrets, monitoring, storage, database).
# =============================================================================
module "infrastructure" {
  source = "../../"

  # ---------------------------------------------------------------------------
  # Project Settings
  # ---------------------------------------------------------------------------
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  # ---------------------------------------------------------------------------
  # ECS Configuration (Development Sizing)
  # Development uses smallest sizing for maximum cost efficiency:
  # - 256 CPU units (0.25 vCPU)
  # - 512 MB memory
  # - 1 desired task
  # - Auto-scaling range: 1-2 tasks
  # ---------------------------------------------------------------------------
  ecs_cluster_name  = var.ecs_cluster_name
  ecs_service_name  = var.ecs_service_name
  ecs_task_name     = var.ecs_task_name
  container_name    = var.container_name
  container_port    = var.container_port
  cpu               = var.cpu
  memory            = var.memory
  desired_count     = var.desired_count
  min_capacity      = var.min_capacity
  max_capacity      = var.max_capacity
  health_check_path = var.health_check_path

  # ---------------------------------------------------------------------------
  # ECR Configuration
  # ---------------------------------------------------------------------------
  ecr_repository_name   = var.ecr_repository_name
  image_retention_count = var.image_retention_count

  # ---------------------------------------------------------------------------
  # Frontend Configuration
  # ---------------------------------------------------------------------------
  frontend_bucket_name = var.frontend_bucket_name

  # ---------------------------------------------------------------------------
  # Networking Configuration
  # Development uses single-AZ NAT gateway for cost savings
  # ---------------------------------------------------------------------------
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones

  # ---------------------------------------------------------------------------
  # GitHub OIDC Configuration
  # Required for CI/CD pipeline authentication
  # ---------------------------------------------------------------------------
  github_org  = var.github_org
  github_repo = var.github_repo

  # ---------------------------------------------------------------------------
  # Database Configuration
  # ---------------------------------------------------------------------------
  dynamodb_table_name = var.dynamodb_table_name

  # ---------------------------------------------------------------------------
  # Monitoring Configuration
  # Development uses shorter retention (7 days) for cost savings
  # ---------------------------------------------------------------------------
  log_retention_days = var.log_retention_days

  # ---------------------------------------------------------------------------
  # Application Configuration
  # ---------------------------------------------------------------------------
  cors_origins = var.cors_origins
}

# =============================================================================
# Output Definitions
# =============================================================================
# Re-exports all outputs from the infrastructure module for CI/CD consumption.
# These values are used by GitHub Actions workflows for deployments.
# =============================================================================

# -----------------------------------------------------------------------------
# ECR Outputs
# -----------------------------------------------------------------------------
output "ecr_repository_url" {
  description = "ECR repository URL for Docker image push operations"
  value       = module.infrastructure.ecr_repository_url
}

output "ecr_repository_arn" {
  description = "ECR repository ARN for IAM policy references"
  value       = module.infrastructure.ecr_repository_arn
}

# -----------------------------------------------------------------------------
# ECS Outputs
# -----------------------------------------------------------------------------
output "ecs_cluster_arn" {
  description = "ECS cluster ARN for deployment operations"
  value       = module.infrastructure.ecs_cluster_arn
}

output "ecs_cluster_name" {
  description = "ECS cluster name for CLI commands"
  value       = module.infrastructure.ecs_cluster_name
}

output "ecs_service_arn" {
  description = "ECS service ARN for service updates"
  value       = module.infrastructure.ecs_service_arn
}

output "ecs_service_name" {
  description = "ECS service name for CLI commands"
  value       = module.infrastructure.ecs_service_name
}

output "ecs_task_definition_arn" {
  description = "ECS task definition ARN"
  value       = module.infrastructure.ecs_task_definition_arn
}

# -----------------------------------------------------------------------------
# Frontend Outputs
# -----------------------------------------------------------------------------
output "frontend_bucket_name" {
  description = "S3 bucket name for frontend static asset deployment"
  value       = module.infrastructure.frontend_bucket_name
}

output "frontend_bucket_arn" {
  description = "S3 bucket ARN for IAM policy references"
  value       = module.infrastructure.frontend_bucket_arn
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID for cache invalidation"
  value       = module.infrastructure.cloudfront_distribution_id
}

output "cloudfront_distribution_domain" {
  description = "CloudFront distribution domain name for application access"
  value       = module.infrastructure.cloudfront_domain_name
}

# -----------------------------------------------------------------------------
# Networking Outputs
# -----------------------------------------------------------------------------
output "vpc_id" {
  description = "VPC identifier"
  value       = module.infrastructure.vpc_id
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name for backend access"
  value       = module.infrastructure.alb_dns_name
}

output "alb_zone_id" {
  description = "ALB hosted zone ID for Route53 alias records"
  value       = module.infrastructure.alb_zone_id
}

# -----------------------------------------------------------------------------
# IAM Outputs
# -----------------------------------------------------------------------------
output "github_actions_role_arn" {
  description = "GitHub Actions OIDC role ARN for CI/CD authentication"
  value       = module.infrastructure.github_actions_role_arn
  sensitive   = true
}

output "ecs_task_execution_role_arn" {
  description = "ECS task execution role ARN"
  value       = module.infrastructure.ecs_task_execution_role_arn
}

output "ecs_task_role_arn" {
  description = "ECS task role ARN"
  value       = module.infrastructure.ecs_task_role_arn
}

# -----------------------------------------------------------------------------
# Database Outputs
# -----------------------------------------------------------------------------
output "dynamodb_table_name" {
  description = "DynamoDB table name for application configuration"
  value       = module.infrastructure.dynamodb_table_name
}

output "dynamodb_table_arn" {
  description = "DynamoDB table ARN for IAM policy references"
  value       = module.infrastructure.dynamodb_table_arn
}

# -----------------------------------------------------------------------------
# Secrets Outputs
# -----------------------------------------------------------------------------
output "secrets_arns" {
  description = "Map of Secrets Manager secret ARNs"
  value       = module.infrastructure.secrets_arns
  sensitive   = true
}

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

# -----------------------------------------------------------------------------
# Monitoring Outputs
# -----------------------------------------------------------------------------
output "log_group_name" {
  description = "Name of the CloudWatch log group for ECS containers"
  value       = module.infrastructure.log_group_name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = module.infrastructure.log_group_arn
}

# -----------------------------------------------------------------------------
# Terraform State Backend Outputs
# -----------------------------------------------------------------------------
output "terraform_state_bucket" {
  description = "Name of the S3 bucket for Terraform state storage"
  value       = module.infrastructure.terraform_state_bucket
}

output "terraform_lock_table" {
  description = "Name of the DynamoDB table for Terraform state locking"
  value       = module.infrastructure.terraform_lock_table
}

# -----------------------------------------------------------------------------
# Additional Networking Outputs
# -----------------------------------------------------------------------------
output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.infrastructure.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.infrastructure.private_subnet_ids
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.infrastructure.alb_arn
}

# -----------------------------------------------------------------------------
# Additional ECR Outputs
# -----------------------------------------------------------------------------
output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = module.infrastructure.ecr_repository_name
}

# -----------------------------------------------------------------------------
# Additional Frontend Outputs
# -----------------------------------------------------------------------------
output "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = module.infrastructure.cloudfront_distribution_arn
}

output "frontend_url" {
  description = "URL of the frontend application"
  value       = module.infrastructure.frontend_url
}

# -----------------------------------------------------------------------------
# Application Outputs
# -----------------------------------------------------------------------------
output "backend_url" {
  description = "URL of the backend API (via ALB)"
  value       = module.infrastructure.backend_url
}

output "aws_region" {
  description = "AWS region where infrastructure is deployed"
  value       = module.infrastructure.aws_region
}

output "environment" {
  description = "Environment name (dev, staging, production)"
  value       = module.infrastructure.environment
}
