# =============================================================================
# Production Environment Terraform Variables
# =============================================================================
# This file contains environment-specific variable values for the production
# deployment of the LangGraph Search Agent infrastructure.
#
# IMPORTANT: This file should be customized for your specific deployment.
# The values below match the existing CI/CD workflow resource naming conventions
# from backend-deploy.yml and frontend-deploy.yml.
#
# Production characteristics:
# - Higher resource allocation (1024 CPU, 2048MB memory)
# - Multi-AZ NAT gateway for high availability
# - Auto-scaling enabled (2-10 tasks)
# - 90-day log retention for compliance
# =============================================================================

# -----------------------------------------------------------------------------
# Project Configuration
# -----------------------------------------------------------------------------
# Core project identification settings that determine resource naming patterns.
# These values should match across all environments for consistency.

# Project name - used as prefix for all resource names
# Must match: langgraph-search-agent (existing CI/CD workflow references)
project_name = "langgraph-search-agent"

# Environment identifier - determines environment-specific configurations
# Valid values: dev, staging, prod
environment = "prod"

# AWS region for all resources (Constraint C-005)
# All infrastructure must be provisioned in us-east-1
aws_region = "us-east-1"

# -----------------------------------------------------------------------------
# ECS Fargate Configuration - Production Sizing
# -----------------------------------------------------------------------------
# Container orchestration settings optimized for production workloads.
# These names MUST match existing CI/CD workflow references exactly.

# ECS cluster name - from backend-deploy.yml line 14
ecs_cluster_name = "langgraph-search-agent-cluster"

# ECS service name - from backend-deploy.yml line 13
ecs_service_name = "langgraph-search-agent-service"

# ECS task definition family name - from backend-deploy.yml line 15
ecs_task_name = "langgraph-search-agent-task"

# Container name within the task definition - from backend-deploy.yml line 61
container_name = "langgraph-search-agent-container"

# Container port - FastAPI application runs on port 8000 (from backend/Dockerfile)
container_port = 8000

# Fargate CPU units - Production sizing (1024 = 1 vCPU)
# Valid values: 256, 512, 1024, 2048, 4096
cpu = 1024

# Fargate memory in MB - Production sizing (2048 MB = 2 GB)
# Must be compatible with CPU: 1024 CPU supports 2048-8192 MB
memory = 2048

# Desired task count - High availability baseline for production
# Ensures multiple instances are always running
desired_count = 2

# Auto-scaling configuration for production workloads
# Minimum capacity - Never scale below this for high availability
min_capacity = 2

# Maximum capacity - Scale up to handle traffic spikes
max_capacity = 10

# Health check endpoint for ALB target group
# Must match backend/app/main.py health check route
health_check_path = "/health"

# -----------------------------------------------------------------------------
# ECR (Elastic Container Registry) Configuration
# -----------------------------------------------------------------------------
# Docker container image repository settings.

# Repository name - from backend-deploy.yml line 12
# Must match existing CI/CD workflow reference exactly
ecr_repository_name = "langgraph-search-agent-backend"

# Number of images to retain (lifecycle policy)
# Older images beyond this count will be automatically deleted
image_retention_count = 10

# -----------------------------------------------------------------------------
# Frontend (S3 + CloudFront) Configuration
# -----------------------------------------------------------------------------
# Static website hosting settings for the React frontend.

# S3 bucket name for static assets - from frontend-deploy.yml line 12
# Must match existing CI/CD workflow reference exactly
frontend_bucket_name = "langgraph-search-agent-frontend-production"

# -----------------------------------------------------------------------------
# VPC Networking Configuration
# -----------------------------------------------------------------------------
# Network infrastructure settings for production environment.

# VPC CIDR block - provides 65,536 IP addresses
# Subnets will be carved from this range
vpc_cidr = "10.0.0.0/16"

# Availability zones for multi-AZ deployment
# Using 2 AZs provides high availability within the region
availability_zones = ["us-east-1a", "us-east-1b"]

# Enable multi-AZ NAT Gateway for production high availability
# true = NAT gateway in each AZ (higher cost, higher availability)
# false = Single NAT gateway (lower cost, single point of failure)
multi_az_nat = true

# -----------------------------------------------------------------------------
# DynamoDB Configuration
# -----------------------------------------------------------------------------
# NoSQL database settings for conversation persistence (future-ready).

# Table name - must match backend/app/config.py DYNAMODB_TABLE_NAME
# Table is provisioned but not actively used until persistence is implemented
dynamodb_table_name = "langgraph-conversations"

# -----------------------------------------------------------------------------
# GitHub Actions OIDC Configuration
# -----------------------------------------------------------------------------
# OpenID Connect authentication settings for CI/CD pipelines.
# OIDC eliminates the need for long-lived AWS credentials.
#
# IMPORTANT: You MUST configure these values for your repository!
# These placeholders will cause Terraform to fail until configured.

# GitHub organization or username (e.g., "my-org" or "my-username")
# Used in IAM trust policy: repo:{github_org}/{github_repo}:*
github_org = ""

# GitHub repository name (e.g., "langgraph-search-agent")
# Used in IAM trust policy: repo:{github_org}/{github_repo}:*
github_repo = ""

# -----------------------------------------------------------------------------
# CloudWatch Monitoring Configuration
# -----------------------------------------------------------------------------
# Logging and monitoring settings for production environment.

# Log retention in days - Production compliance requirement
# Higher retention for audit and troubleshooting purposes
# Valid values: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
log_retention_days = 90

# -----------------------------------------------------------------------------
# Application Configuration
# -----------------------------------------------------------------------------
# Runtime configuration passed to containers via environment variables.

# CORS allowed origins for the backend API
# WARNING: In production, this should be restricted to your frontend domain!
# Example: ["https://your-domain.com", "https://www.your-domain.com"]
# Using ["*"] allows any origin - suitable for initial deployment only
cors_origins = ["*"]

# =============================================================================
# Post-Deployment Notes
# =============================================================================
#
# After terraform apply completes successfully:
#
# 1. Update github_org and github_repo values above
#
# 2. Configure GitHub Secrets (Settings > Secrets and variables > Actions):
#    - AWS_ROLE_ARN: Copy from Terraform output github_actions_role_arn
#    - OPENAI_API_KEY: Your OpenAI API key
#    - TAVILY_API_KEY: Your Tavily API key
#    - CLOUDFRONT_DISTRIBUTION_ID: Copy from Terraform output cloudfront_distribution_id
#    - API_URL: Copy ALB DNS from Terraform output (e.g., http://alb-dns-name.us-east-1.elb.amazonaws.com)
#
# 3. Update API secrets in AWS Secrets Manager:
#    - openai-api-key: Set the actual OpenAI API key
#    - tavily-api-key: Set the actual Tavily API key
#
# 4. Trigger deployment workflows:
#    - Push to main branch in backend/ to deploy backend
#    - Push to main branch in frontend/ to deploy frontend
#
# 5. Verify production deployment:
#    - Check ECS service tasks are healthy
#    - Test API endpoint via ALB DNS
#    - Verify frontend loads via CloudFront distribution
#
# =============================================================================
