#------------------------------------------------------------------------------
# Staging Environment Terraform Variables Configuration
#
# This file contains staging-specific variable values for the LangGraph Search
# Agent infrastructure on AWS. The staging environment is designed for
# pre-production validation testing with medium resource sizing.
#
# ENVIRONMENT CHARACTERISTICS:
# - Medium compute resources (512 CPU, 1024MB memory)
# - Auto-scaling range: 1-3 tasks for limited scaling
# - Single-AZ NAT Gateway for cost savings
# - 30-day log retention
# - Staging-specific resource naming with "-staging" suffix
#
# USAGE:
# 1. Navigate to the staging environment directory:
#    cd infrastructure/terraform/environments/staging
#
# 2. Initialize Terraform:
#    terraform init
#
# 3. Plan changes:
#    terraform plan
#
# 4. Apply changes:
#    terraform apply
#
# IMPORTANT:
# - Update github_org and github_repo with your actual values before deployment
# - All resource names follow the langgraph-search-agent naming pattern
# - AWS region is us-east-1 per project requirements (Constraint C-005)
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Project Configuration
#------------------------------------------------------------------------------

# Name of the project used for resource naming and tagging
# This name is used as a prefix for most AWS resources
# Matches existing CI/CD workflow resource naming conventions
project_name = "langgraph-search-agent"

# Deployment environment identifier
# Affects resource sizing, scaling parameters, and naming
environment = "staging"

# AWS region where all resources will be provisioned
# IMPORTANT: Must be us-east-1 per project requirements (Constraint C-005)
aws_region = "us-east-1"

#------------------------------------------------------------------------------
# Resource Tagging Configuration
#------------------------------------------------------------------------------

# Additional tags to apply to all resources
# Common tags (Project, Environment, ManagedBy, Region) are automatically applied
tags = {
  # Staging environment specific tags
  # Add organization-specific tags as needed
}

#------------------------------------------------------------------------------
# ECR Configuration
#------------------------------------------------------------------------------

# Name of the ECR repository for storing backend Docker images
# MUST match the CI/CD workflow configuration in backend-deploy.yml
ecr_repository_name = "langgraph-search-agent-backend"

# Number of tagged Docker images to retain in ECR
# Older images will be automatically deleted by lifecycle policy
# Using 10 for staging to match production for consistent testing
image_retention_count = 10

# Enable image vulnerability scanning on push to ECR repository
# Enabled for security validation in staging
ecr_scan_on_push = true

#------------------------------------------------------------------------------
# ECS Configuration (Staging Sizing - Medium)
#
# As specified in Agent Action Plan Section 0.7.3:
# - CPU: 512 (medium)
# - Memory: 1024 (medium)
# - Desired Count: 1 (cost-effective)
# - Min Capacity: 1
# - Max Capacity: 3 (limited scaling)
#------------------------------------------------------------------------------

# Name of the ECS cluster for running Fargate tasks
# MUST match the CI/CD workflow configuration in backend-deploy.yml
ecs_cluster_name = "langgraph-search-agent-cluster"

# Name of the ECS service managing the Fargate tasks
# MUST match the CI/CD workflow configuration in backend-deploy.yml
ecs_service_name = "langgraph-search-agent-service"

# Name of the ECS task definition for the backend container
# MUST match the CI/CD workflow configuration in backend-deploy.yml
ecs_task_name = "langgraph-search-agent-task"

# Name of the container within the ECS task definition
# MUST match the CI/CD workflow configuration in backend-deploy.yml
container_name = "langgraph-search-agent-container"

# Port number the backend container listens on
# FastAPI application runs on port 8000 as defined in backend/Dockerfile
container_port = 8000

# Fargate CPU units for the task
# Staging sizing: 512 (medium) - cost-effective for validation testing
# Valid values: 256, 512, 1024, 2048, 4096
cpu = 512

# Fargate memory in MB for the task
# Staging sizing: 1024 (medium) - balanced for validation workloads
# Must be compatible with selected CPU value per AWS Fargate requirements
memory = 1024

# Desired number of ECS tasks to run
# Staging: 1 task for cost-effective validation testing
desired_count = 1

# Minimum number of ECS tasks for auto-scaling
# Staging: 1 task minimum for cost savings during low usage
min_capacity = 1

# Maximum number of ECS tasks for auto-scaling
# Staging: 3 tasks maximum for limited scaling capability
max_capacity = 3

# HTTP path for ALB health checks
# The FastAPI backend exposes health status at /health endpoint
health_check_path = "/health"

# Interval between health checks in seconds
health_check_interval = 30

# Health check timeout in seconds (must be less than interval)
health_check_timeout = 5

# Number of consecutive successful health checks to mark target healthy
health_check_healthy_threshold = 2

# Number of consecutive failed health checks to mark target unhealthy
health_check_unhealthy_threshold = 3

#------------------------------------------------------------------------------
# Auto-Scaling Configuration (Staging)
#------------------------------------------------------------------------------

# Target CPU utilization percentage for auto-scaling
# Using 70% target for balanced performance in staging
cpu_target_value = 70

# Cooldown period in seconds after a scale-out activity completes
# Staging: 60 seconds for responsive scaling during testing
scale_out_cooldown = 60

# Cooldown period in seconds after a scale-in activity completes
# Staging: 120 seconds for quicker scale-in during testing
scale_in_cooldown = 120

#------------------------------------------------------------------------------
# Frontend Configuration (Staging)
#------------------------------------------------------------------------------

# Name of the S3 bucket for hosting frontend static assets
# Using staging-specific bucket name for environment isolation
# S3 bucket names must be globally unique
frontend_bucket_name = "langgraph-search-agent-frontend-staging"

# CloudFront price class determining which edge locations to use
# PriceClass_100 for cost-effective staging (US, Canada, Europe)
cloudfront_price_class = "PriceClass_100"

# Default TTL in seconds for CloudFront cache when no Cache-Control header is set
# 86400 seconds = 24 hours
cloudfront_default_ttl = 86400

# Maximum TTL in seconds for CloudFront cache
# 31536000 seconds = 1 year
cloudfront_max_ttl = 31536000

# Minimum TTL in seconds for CloudFront cache
cloudfront_min_ttl = 0

#------------------------------------------------------------------------------
# Networking Configuration (Staging - Cost Optimized)
#
# As specified in Agent Action Plan Section 0.7.3:
# - NAT Gateway: Single AZ (cost savings)
# - VPC CIDR: 10.0.0.0/16
# - 2 Availability Zones: us-east-1a, us-east-1b
#------------------------------------------------------------------------------

# CIDR block for the VPC
# Provides the IP address range for all VPC resources
vpc_cidr = "10.0.0.0/16"

# List of availability zones for multi-AZ deployment
# Using 2 AZs for basic high availability in staging
availability_zones = ["us-east-1a", "us-east-1b"]

# CIDR blocks for public subnets
# Must be within the VPC CIDR range
# One subnet per availability zone
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]

# CIDR blocks for private subnets
# Must be within the VPC CIDR range
# One subnet per availability zone
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]

# Enable NAT Gateway for private subnet internet access
# Required for ECS tasks to pull images and access external APIs
enable_nat_gateway = true

# Use a single NAT Gateway for all availability zones
# Staging: true for cost savings (single NAT Gateway shared across AZs)
# Production uses false for multi-AZ NAT Gateways
single_nat_gateway = true

#------------------------------------------------------------------------------
# GitHub OIDC Configuration
#
# IMPORTANT: You MUST update these placeholder values before deployment!
# These values configure the OIDC trust relationship for secure CI/CD
# authentication without long-lived AWS credentials.
#------------------------------------------------------------------------------

# GitHub organization or username owning the repository
# PLACEHOLDER: Replace with your actual GitHub organization
github_org = "your-github-org"

# GitHub repository name
# PLACEHOLDER: Replace with your actual repository name
github_repo = "your-repo-name"

# GitHub Actions OIDC provider thumbprint
# Default is the current GitHub thumbprint (as of 2024)
# Only change if GitHub updates their OIDC certificate
github_oidc_thumbprint = "6938fd4d98bab03faadb97b34396831e3780aea1"

#------------------------------------------------------------------------------
# Database Configuration (Staging)
#------------------------------------------------------------------------------

# Name of the DynamoDB table for storing conversation sessions
# Using staging-specific table name for environment isolation
# Table is provisioned but not actively used (future-ready)
dynamodb_table_name = "langgraph-conversations-staging"

# DynamoDB billing mode
# PAY_PER_REQUEST: On-demand scaling without capacity planning (recommended)
dynamodb_billing_mode = "PAY_PER_REQUEST"

# Enable TTL (Time to Live) for automatic expiration of old sessions
dynamodb_ttl_enabled = true

# Name of the TTL attribute for DynamoDB
# Items with expired TTL values are automatically deleted
dynamodb_ttl_attribute = "expiration"

#------------------------------------------------------------------------------
# Application Configuration (Staging)
#------------------------------------------------------------------------------

# List of allowed CORS origins for the backend API
# Staging: Using permissive CORS for testing flexibility
# Update to specific origins for tighter security if needed
cors_origins = ["*"]

# Base URL for the backend API (optional)
# Leave empty to use ALB DNS name dynamically
api_url = ""

#------------------------------------------------------------------------------
# Monitoring Configuration (Staging)
#------------------------------------------------------------------------------

# Number of days to retain CloudWatch logs
# Staging: 30 days for shorter retention (cost savings)
# Production typically uses longer retention (90+ days)
log_retention_days = 30

# Enable CloudWatch Container Insights for detailed ECS monitoring
# Enabled for staging to test monitoring capabilities
enable_container_insights = true

# Enable ECS Exec for debugging containers
# Enabled in staging for easier debugging during validation
enable_execute_command = true

#------------------------------------------------------------------------------
# Secrets Configuration (Staging)
#------------------------------------------------------------------------------

# Create Secrets Manager secrets for API keys
# Set to true to create placeholder secrets
create_secrets = true

# Name of the Secrets Manager secret containing the OpenAI API key
# Using staging-specific naming for environment isolation
openai_api_key_secret_name = "langgraph-search-agent/staging/openai-api-key"

# Name of the Secrets Manager secret containing the Tavily API key
# Using staging-specific naming for environment isolation
tavily_api_key_secret_name = "langgraph-search-agent/staging/tavily-api-key"

#------------------------------------------------------------------------------
# Terraform State Backend Configuration
#------------------------------------------------------------------------------

# S3 bucket name for storing Terraform state files
# Shared across environments; state isolation via key path
terraform_state_bucket = "langgraph-search-agent-terraform-state"

# DynamoDB table name for Terraform state locking
terraform_state_lock_table = "langgraph-search-agent-terraform-locks"

# S3 key path for the Terraform state file
# Staging-specific state file path for environment isolation
terraform_state_key = "state/staging/terraform.tfstate"

#------------------------------------------------------------------------------
# ALB Configuration (Staging)
#------------------------------------------------------------------------------

# Set to false for internet-facing ALB (accessible from the internet)
# Staging uses internet-facing ALB for external testing access
alb_internal = false

# Time in seconds that the connection is allowed to be idle
alb_idle_timeout = 60

# Enable deletion protection for the ALB
# Staging: false to allow easier cleanup during testing
alb_deletion_protection = false

# Enable HTTPS on the ALB
# Staging: false unless you have a valid ACM certificate
# Set to true and provide acm_certificate_arn for HTTPS
enable_https = false

# ARN of the ACM certificate for HTTPS
# Required if enable_https is true
acm_certificate_arn = ""

# SSL policy for the HTTPS listener
# Only used if enable_https is true
ssl_policy = "ELBSecurityPolicy-TLS13-1-2-2021-06"
