#------------------------------------------------------------------------------
# LangGraph Search Agent - Root Terraform Configuration
#------------------------------------------------------------------------------
# This is the root module that orchestrates all child infrastructure modules
# for the LangGraph Search Agent application. It provisions AWS resources
# including container registry, networking, compute (ECS Fargate), frontend
# hosting (S3/CloudFront), database (DynamoDB), and supporting services.
#
# Module Dependency Order:
#   1. Independent: ecr, networking, secrets, monitoring, storage, database
#   2. Dependent: iam (needs ecr ARN, frontend bucket ARN)
#   3. Dependent: ecs_fargate (needs networking, iam, secrets, monitoring)
#   4. Dependent: frontend (independent but outputs needed by iam)
#
# Usage:
#   terraform init
#   terraform plan
#   terraform apply
#
# For environment-specific deployments, use the environments/ directory.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# AWS Provider Configuration
#------------------------------------------------------------------------------
# Configure the AWS provider with the specified region and default tags
# that will be applied to all resources created by this configuration.
#------------------------------------------------------------------------------
provider "aws" {
  region = var.aws_region

  # Default tags applied to all resources created by this provider
  # These ensure consistent tagging across all infrastructure components
  default_tags {
    tags = local.common_tags
  }
}

#------------------------------------------------------------------------------
# ECR Module - Container Registry
#------------------------------------------------------------------------------
# Creates an ECR repository for storing Docker images of the backend application.
# This module is independent and can be created first.
#
# Key Features:
#   - Image scanning on push for vulnerability detection
#   - Lifecycle policy to retain only the last N tagged images
#   - AES256 encryption for images at rest
#
# Integration Points:
#   - Repository URL used by ecs_fargate module for container image reference
#   - Repository ARN used by iam module for push/pull permissions
#------------------------------------------------------------------------------
module "ecr" {
  source = "./modules/ecr"

  repository_name       = var.ecr_repository_name
  image_retention_count = var.image_retention_count
  scan_on_push          = true
  image_tag_mutability  = "MUTABLE"
  force_delete          = false

  tags = local.common_tags
}

#------------------------------------------------------------------------------
# Networking Module - VPC Infrastructure
#------------------------------------------------------------------------------
# Creates the complete VPC networking infrastructure including:
#   - VPC with DNS support enabled
#   - Public subnets (for ALB placement)
#   - Private subnets (for ECS Fargate tasks)
#   - Internet Gateway (public internet access)
#   - NAT Gateway (outbound access for private subnets)
#   - Route tables and associations
#   - Security groups (ALB and ECS)
#
# This module is independent and can be created in parallel with ECR.
#------------------------------------------------------------------------------
module "networking" {
  source = "./modules/networking"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  container_port     = var.container_port

  tags = local.common_tags
}

#------------------------------------------------------------------------------
# Secrets Module - AWS Secrets Manager
#------------------------------------------------------------------------------
# Creates Secrets Manager secrets for sensitive configuration values:
#   - OPENAI_API_KEY - OpenAI API key for LLM interactions
#   - TAVILY_API_KEY - Tavily API key for web search functionality
#
# This module is independent and creates placeholder values.
# Actual secret values should be updated via AWS Console or CLI after deployment.
#
# Integration Points:
#   - Secret ARNs used by ecs_fargate module for container environment
#   - Secret ARNs used by iam module for task execution role permissions
#------------------------------------------------------------------------------
module "secrets" {
  source = "./modules/secrets"

  project_name            = var.project_name
  environment             = var.environment
  recovery_window_in_days = 7

  tags = local.common_tags
}

#------------------------------------------------------------------------------
# Monitoring Module - CloudWatch Resources
#------------------------------------------------------------------------------
# Creates CloudWatch resources for application monitoring:
#   - Log group for ECS container logs (/ecs/langgraph-search-agent)
#   - Optional metric alarms for CPU and memory utilization
#
# This module is independent and provides log configuration for ECS tasks.
#
# Integration Points:
#   - Log group name used by ecs_fargate module for container logging
#   - Log group ARN used by iam module for log write permissions
#------------------------------------------------------------------------------
module "monitoring" {
  source = "./modules/monitoring"

  project_name       = var.project_name
  log_group_name     = "/ecs/${var.project_name}"
  log_retention_days = var.log_retention_days
  enable_alarms      = false

  tags = local.common_tags
}

#------------------------------------------------------------------------------
# Storage Module - Terraform State Backend Resources
#------------------------------------------------------------------------------
# Creates infrastructure for Terraform remote state management:
#   - S3 bucket for state file storage with versioning and encryption
#   - DynamoDB table for state locking to prevent concurrent modifications
#
# Note: These resources support the backend configuration in backend.tf.
# The bucket and table must exist before running terraform init with remote state.
# For initial setup, you may need to bootstrap these resources manually or
# temporarily use local state.
#------------------------------------------------------------------------------
module "storage" {
  source = "./modules/storage"

  state_bucket_name = "${var.project_name}-terraform-state"
  lock_table_name   = "${var.project_name}-terraform-locks"
  enable_versioning = true
  force_destroy     = false

  tags = local.common_tags
}

#------------------------------------------------------------------------------
# Database Module - DynamoDB Table
#------------------------------------------------------------------------------
# Creates the DynamoDB table for conversation persistence:
#   - Table name: langgraph-conversations (matches backend/app/config.py)
#   - Partition key: session_id (String)
#   - Sort key: timestamp (Number)
#   - Billing: PAY_PER_REQUEST (on-demand scaling)
#   - TTL: Enabled on 'expiration' attribute for automatic cleanup
#
# Note: This table is provisioned for future use. The current application
# uses in-memory state (MemorySaver) but the table is ready for when
# conversation persistence is implemented.
#------------------------------------------------------------------------------
module "database" {
  source = "./modules/database"

  table_name                     = var.dynamodb_table_name
  ttl_enabled                    = true
  point_in_time_recovery_enabled = true

  tags = local.common_tags
}

#------------------------------------------------------------------------------
# Frontend Module - S3 Static Hosting + CloudFront CDN
#------------------------------------------------------------------------------
# Creates the frontend hosting infrastructure:
#   - S3 bucket for static assets (React/Vite build output)
#   - CloudFront distribution for global content delivery
#   - Origin Access Identity (OAI) for secure S3 access
#   - Bucket policy restricting access to CloudFront only
#
# SPA Optimizations:
#   - Custom error responses route 404s to index.html
#   - HTTPS redirect for secure connections
#   - Compression enabled for faster delivery
#
# Integration Points:
#   - Bucket name used by frontend-deploy.yml for S3 sync
#   - Distribution ID used for CloudFront cache invalidation
#------------------------------------------------------------------------------
module "frontend" {
  source = "./modules/frontend"

  project_name  = var.project_name
  environment   = var.environment
  bucket_name   = var.frontend_bucket_name
  force_destroy = false

  tags = local.common_tags
}

#------------------------------------------------------------------------------
# IAM Module - Identity and Access Management
#------------------------------------------------------------------------------
# Creates IAM roles and policies for:
#   1. GitHub Actions OIDC Provider - Enables passwordless authentication
#   2. GitHub Actions Role - Permissions for CI/CD workflows
#   3. ECS Task Execution Role - Permissions for task startup (ECR pull, logs)
#   4. ECS Task Role - Container runtime permissions (DynamoDB, etc.)
#
# OIDC Integration:
#   - Eliminates need for long-lived AWS credentials in GitHub
#   - Trust policy scoped to specific repository
#
# Dependencies:
#   - ecr.repository_arn - For ECR push/pull permissions
#   - frontend.bucket_arn - For S3 sync permissions
#   - secrets.secret_arns - For Secrets Manager read permissions
#   - database.table_arn - For DynamoDB access permissions
#   - monitoring.log_group_arn - For CloudWatch log permissions
#------------------------------------------------------------------------------
module "iam" {
  source = "./modules/iam"

  project_name                = var.project_name
  environment                 = var.environment
  github_org                  = var.github_org
  github_repo                 = var.github_repo
  ecr_repository_arn          = module.ecr.repository_arn
  s3_bucket_arn               = module.frontend.bucket_arn
  cloudfront_distribution_arn = module.frontend.distribution_arn
  ecs_cluster_arn             = "" # Will be set after ECS cluster creation via data source or targeted apply
  ecs_service_arn             = "" # Will be set after ECS service creation via data source or targeted apply
  dynamodb_table_arn          = module.database.table_arn
  secrets_arns                = values(module.secrets.secret_arns)
  log_group_arn               = module.monitoring.log_group_arn

  tags = local.common_tags

  # IAM module depends on modules that provide ARNs for policies
  depends_on = [
    module.ecr,
    module.frontend,
    module.secrets,
    module.database,
    module.monitoring
  ]
}

#------------------------------------------------------------------------------
# ECS Fargate Module - Container Orchestration
#------------------------------------------------------------------------------
# Creates the complete ECS infrastructure for running the backend API:
#   - ECS Cluster with Fargate capacity provider
#   - ECS Service with rolling deployment configuration
#   - ECS Task Definition for the FastAPI container
#   - Application Load Balancer (internet-facing)
#   - Target Group with health check on /health endpoint
#   - HTTP Listener on port 80
#   - Auto Scaling with CPU-based scaling policy
#
# Container Configuration:
#   - Image: From ECR repository
#   - Port: 8000 (FastAPI)
#   - Health Check: /health endpoint
#   - Logging: CloudWatch Logs via awslogs driver
#   - Secrets: OPENAI_API_KEY, TAVILY_API_KEY from Secrets Manager
#
# Network Configuration:
#   - ALB in public subnets (internet-facing)
#   - ECS tasks in private subnets (no public IP)
#   - NAT Gateway for outbound API calls (OpenAI, Tavily)
#
# Scaling Configuration:
#   - Min/Max capacity from variables (default: 2-10)
#   - CPU target: 70%
#   - Scale-out cooldown: 60s
#   - Scale-in cooldown: 300s (production) or 120s (dev/staging)
#------------------------------------------------------------------------------
module "ecs_fargate" {
  source = "./modules/ecs-fargate"

  # Project identification
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  # ECS cluster configuration
  cluster_name              = var.ecs_cluster_name
  enable_container_insights = var.environment == "production" || var.environment == "prod"

  # ECS service configuration
  service_name  = var.ecs_service_name
  desired_count = var.desired_count

  # Task definition configuration
  task_family = var.ecs_task_name
  task_cpu    = var.cpu
  task_memory = var.memory

  # Container configuration
  container_name  = var.container_name
  container_image = module.ecr.repository_url
  container_port  = var.container_port

  # Application environment
  dynamodb_table_name = var.dynamodb_table_name
  cors_origins        = join(",", var.cors_origins)

  # Network configuration (from networking module)
  vpc_id                = module.networking.vpc_id
  public_subnet_ids     = module.networking.public_subnet_ids
  private_subnet_ids    = module.networking.private_subnet_ids
  alb_security_group_id = module.networking.alb_security_group_id
  ecs_security_group_id = module.networking.ecs_security_group_id

  # IAM roles (from iam module)
  execution_role_arn = module.iam.task_execution_role_arn
  task_role_arn      = module.iam.task_role_arn

  # Secrets Manager (from secrets module)
  openai_secret_arn = module.secrets.secret_arns["OPENAI_API_KEY"]
  tavily_secret_arn = module.secrets.secret_arns["TAVILY_API_KEY"]

  # CloudWatch logging (from monitoring module)
  log_group_name = module.monitoring.log_group_name

  # ALB configuration
  alb_name                   = "${var.project_name}-alb"
  enable_deletion_protection = var.environment == "production" || var.environment == "prod"
  health_check_path          = var.health_check_path

  # Auto-scaling configuration
  min_capacity       = var.min_capacity
  max_capacity       = var.max_capacity
  cpu_target_value   = 70
  scale_in_cooldown  = var.environment == "production" || var.environment == "prod" ? 300 : 120
  scale_out_cooldown = 60

  tags = local.common_tags

  # ECS module depends on all its input providers
  depends_on = [
    module.ecr,
    module.networking,
    module.iam,
    module.secrets,
    module.monitoring
  ]
}
