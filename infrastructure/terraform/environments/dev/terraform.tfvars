# =============================================================================
# LangGraph Search Agent - Development Environment Terraform Variables
# =============================================================================
# This file contains the development environment-specific variable values for
# deploying the LangGraph Search Agent infrastructure. Development environment
# uses the smallest, most cost-effective resource sizing for testing and
# validation before promoting to staging/production.
#
# Environment Characteristics:
# - Minimal resource sizing (256 CPU units, 512MB memory)
# - Limited auto-scaling (1-2 tasks)
# - Single-AZ NAT gateway for cost savings
# - Shorter log retention (7 days)
# - Open CORS configuration for development flexibility
#
# Usage:
#   cd infrastructure/terraform/environments/dev
#   terraform init
#   terraform plan
#   terraform apply
#
# Note: Update github_org and github_repo with your actual values before
# deploying to enable GitHub Actions OIDC authentication.
# =============================================================================

# -----------------------------------------------------------------------------
# Project and Environment Settings
# -----------------------------------------------------------------------------
# Core project identification - matches existing CI/CD workflow resource names
project_name = "langgraph-search-agent"

# Environment identifier - used for resource naming and tagging
environment = "dev"

# AWS region - per constraint C-005, all resources in us-east-1 exclusively
aws_region = "us-east-1"

# -----------------------------------------------------------------------------
# ECS Fargate Configuration (Development Sizing)
# -----------------------------------------------------------------------------
# Cluster, service, and task names aligned with existing CI/CD workflows
# See: .github/workflows/backend-deploy.yml for reference

# ECS cluster name - matches backend-deploy.yml env.ECS_CLUSTER
ecs_cluster_name = "langgraph-search-agent-cluster"

# ECS service name - matches backend-deploy.yml env.ECS_SERVICE
ecs_service_name = "langgraph-search-agent-service"

# ECS task definition name - matches backend-deploy.yml env.ECS_TASK_DEFINITION
ecs_task_name = "langgraph-search-agent-task"

# Container name within task definition - matches amazon-ecs-render-task-definition action
container_name = "langgraph-search-agent-container"

# Container port - FastAPI application port (matches backend/Dockerfile EXPOSE)
container_port = 8000

# CPU units - Development sizing (smallest: 256 = 0.25 vCPU)
# Per Agent Action Plan Section 0.7.3: Development = 256
cpu = 256

# Memory in MB - Development sizing (smallest: 512MB)
# Per Agent Action Plan Section 0.7.3: Development = 512
memory = 512

# Desired task count - Minimal for development cost efficiency
# Per Agent Action Plan Section 0.7.3: Development desired = 1
desired_count = 1

# Auto-scaling minimum capacity - Development minimum
# Per Agent Action Plan Section 0.7.3: Development min = 1
min_capacity = 1

# Auto-scaling maximum capacity - Development limited scaling
# Per Agent Action Plan Section 0.7.3: Development max = 2
max_capacity = 2

# Health check endpoint path for ALB target group
# Matches backend/app/main.py health check route
health_check_path = "/health"

# -----------------------------------------------------------------------------
# ECR (Elastic Container Registry) Configuration
# -----------------------------------------------------------------------------
# Repository name - matches backend-deploy.yml env.ECR_REPOSITORY
ecr_repository_name = "langgraph-search-agent-backend"

# Lifecycle policy - retain only the last N tagged images
# Per Agent Action Plan: retain last 10 images
image_retention_count = 10

# -----------------------------------------------------------------------------
# Frontend (S3 + CloudFront) Configuration
# -----------------------------------------------------------------------------
# S3 bucket name for frontend static assets
# Development environment uses -dev suffix for isolation
# Production pattern from frontend-deploy.yml: langgraph-search-agent-frontend-production
frontend_bucket_name = "langgraph-search-agent-frontend-dev"

# -----------------------------------------------------------------------------
# Networking Configuration (Development)
# -----------------------------------------------------------------------------
# VPC CIDR block - provides sufficient IP space for development
vpc_cidr = "10.0.0.0/16"

# Availability zones for subnet distribution
# Using 2 AZs in us-east-1 for basic high availability
availability_zones = ["us-east-1a", "us-east-1b"]

# Multi-AZ NAT Gateway configuration
# Development: false (single AZ) for cost savings
# Production: true (multi-AZ) for high availability
# Per Agent Action Plan Section 0.7.3: Development uses single AZ
multi_az_nat = false

# -----------------------------------------------------------------------------
# Database (DynamoDB) Configuration
# -----------------------------------------------------------------------------
# DynamoDB table name for session persistence (future-ready)
# Development environment uses -dev suffix for isolation
# Base name from backend/app/config.py: langgraph-conversations
dynamodb_table_name = "langgraph-conversations-dev"

# -----------------------------------------------------------------------------
# GitHub OIDC Configuration
# -----------------------------------------------------------------------------
# IMPORTANT: Update these values with your actual GitHub organization and
# repository names before deploying. These are required for GitHub Actions
# OIDC authentication (eliminates long-lived AWS credentials).
#
# Example:
#   github_org  = "my-organization"
#   github_repo = "langgraph-search-agent"

# GitHub organization or username owning the repository
github_org = ""

# GitHub repository name (without org/username prefix)
github_repo = ""

# -----------------------------------------------------------------------------
# Monitoring Configuration
# -----------------------------------------------------------------------------
# CloudWatch log retention in days - Development uses shorter retention
# for cost savings. Logs older than this are automatically deleted.
# Per Agent Action Plan Section 0.7.3: Development = 7 days (shortest)
log_retention_days = 7

# -----------------------------------------------------------------------------
# Application Configuration
# -----------------------------------------------------------------------------
# CORS allowed origins - Development uses wildcard for flexibility
# Production should specify exact frontend domains for security
# Note: Backend FastAPI app reads CORS_ORIGINS environment variable
cors_origins = ["*"]

# -----------------------------------------------------------------------------
# Auto-scaling Configuration (Development-specific)
# -----------------------------------------------------------------------------
# CPU utilization target percentage for auto-scaling policy
# When average CPU exceeds this threshold, scale out
cpu_target_value = 70

# Scale-out cooldown in seconds - Time to wait before another scale-out
scale_out_cooldown = 60

# Scale-in cooldown in seconds - Time to wait before scale-in
# Development uses shorter cooldown for faster scale-down
scale_in_cooldown = 120

# -----------------------------------------------------------------------------
# Resource Tagging (Applied via locals in main configuration)
# -----------------------------------------------------------------------------
# All resources will be tagged with:
#   Project     = "langgraph-search-agent"
#   Environment = "dev"
#   ManagedBy   = "terraform"
#   Region      = "us-east-1"
# Tags are defined in root locals.tf and applied via AWS provider default_tags
