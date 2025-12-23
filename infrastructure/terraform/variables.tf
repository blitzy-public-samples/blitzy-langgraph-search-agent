#------------------------------------------------------------------------------
# Terraform Variables Configuration
# 
# This file declares all input variables for the LangGraph Search Agent
# infrastructure. Variables are organized by category with comprehensive
# type constraints, descriptions, defaults, and validation blocks.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Project Configuration
#------------------------------------------------------------------------------

variable "project_name" {
  description = "Name of the project used for resource naming and tagging. This name is used as a prefix for most AWS resources."
  type        = string
  default     = "langgraph-search-agent"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }

  validation {
    condition     = length(var.project_name) >= 3 && length(var.project_name) <= 50
    error_message = "Project name must be between 3 and 50 characters."
  }
}

variable "environment" {
  description = "Deployment environment (dev, staging, or production). Affects resource sizing and naming."
  type        = string
  default     = "production"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}

variable "aws_region" {
  description = "AWS region where all resources will be provisioned. Must be us-east-1 per project requirements."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = var.aws_region == "us-east-1"
    error_message = "AWS region must be us-east-1 per project requirements."
  }
}

#------------------------------------------------------------------------------
# Resource Tagging Configuration
#------------------------------------------------------------------------------

variable "tags" {
  description = "Additional tags to apply to all resources. Common tags (Project, Environment, ManagedBy, Region) are automatically applied."
  type        = map(string)
  default     = {}
}

#------------------------------------------------------------------------------
# ECR Configuration
#------------------------------------------------------------------------------

variable "ecr_repository_name" {
  description = "Name of the ECR repository for storing backend Docker images. Must match the CI/CD workflow configuration."
  type        = string
  default     = "langgraph-search-agent-backend"

  validation {
    condition     = can(regex("^[a-z0-9-/]+$", var.ecr_repository_name))
    error_message = "ECR repository name must contain only lowercase letters, numbers, hyphens, and forward slashes."
  }
}

variable "image_retention_count" {
  description = "Number of tagged Docker images to retain in ECR. Older images will be automatically deleted by lifecycle policy."
  type        = number
  default     = 10

  validation {
    condition     = var.image_retention_count >= 1 && var.image_retention_count <= 100
    error_message = "Image retention count must be between 1 and 100."
  }
}

variable "ecr_scan_on_push" {
  description = "Enable image vulnerability scanning on push to ECR repository."
  type        = bool
  default     = true
}

#------------------------------------------------------------------------------
# ECS Configuration
#------------------------------------------------------------------------------

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster for running Fargate tasks. Must match the CI/CD workflow configuration."
  type        = string
  default     = "langgraph-search-agent-cluster"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.ecs_cluster_name))
    error_message = "ECS cluster name must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "ecs_service_name" {
  description = "Name of the ECS service managing the Fargate tasks. Must match the CI/CD workflow configuration."
  type        = string
  default     = "langgraph-search-agent-service"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.ecs_service_name))
    error_message = "ECS service name must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "ecs_task_name" {
  description = "Name of the ECS task definition for the backend container. Must match the CI/CD workflow configuration."
  type        = string
  default     = "langgraph-search-agent-task"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.ecs_task_name))
    error_message = "ECS task name must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "container_name" {
  description = "Name of the container within the ECS task definition. Must match the CI/CD workflow configuration."
  type        = string
  default     = "langgraph-search-agent-container"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.container_name))
    error_message = "Container name must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "container_port" {
  description = "Port number the backend container listens on. FastAPI application runs on port 8000."
  type        = number
  default     = 8000

  validation {
    condition     = var.container_port > 0 && var.container_port <= 65535
    error_message = "Container port must be a valid port number between 1 and 65535."
  }
}

variable "cpu" {
  description = "Fargate CPU units for the task (256, 512, 1024, 2048, 4096). Higher values provide more compute capacity."
  type        = number
  default     = 1024

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.cpu)
    error_message = "CPU must be one of: 256, 512, 1024, 2048, 4096."
  }
}

variable "memory" {
  description = "Fargate memory in MB for the task. Must be compatible with the selected CPU value per AWS Fargate requirements."
  type        = number
  default     = 2048

  validation {
    condition     = contains([512, 1024, 2048, 3072, 4096, 5120, 6144, 7168, 8192, 9216, 10240, 11264, 12288, 13312, 14336, 15360, 16384, 17408, 18432, 19456, 20480, 21504, 22528, 23552, 24576, 25600, 26624, 27648, 28672, 29696, 30720], var.memory)
    error_message = "Memory must be a valid Fargate memory value. See AWS documentation for valid CPU/memory combinations."
  }
}

variable "desired_count" {
  description = "Desired number of ECS tasks to run. This is the target count that the service will try to maintain."
  type        = number
  default     = 2

  validation {
    condition     = var.desired_count >= 0 && var.desired_count <= 100
    error_message = "Desired count must be between 0 and 100."
  }
}

variable "min_capacity" {
  description = "Minimum number of ECS tasks for auto-scaling. The service will never scale below this number."
  type        = number
  default     = 2

  validation {
    condition     = var.min_capacity >= 1 && var.min_capacity <= 100
    error_message = "Minimum capacity must be between 1 and 100."
  }
}

variable "max_capacity" {
  description = "Maximum number of ECS tasks for auto-scaling. The service will never scale above this number."
  type        = number
  default     = 10

  validation {
    condition     = var.max_capacity >= 1 && var.max_capacity <= 100
    error_message = "Maximum capacity must be between 1 and 100."
  }
}

variable "health_check_path" {
  description = "HTTP path for ALB health checks. The FastAPI backend exposes health status at /health endpoint."
  type        = string
  default     = "/health"

  validation {
    condition     = can(regex("^/", var.health_check_path))
    error_message = "Health check path must start with a forward slash."
  }
}

variable "health_check_interval" {
  description = "Interval between health checks in seconds."
  type        = number
  default     = 30

  validation {
    condition     = var.health_check_interval >= 5 && var.health_check_interval <= 300
    error_message = "Health check interval must be between 5 and 300 seconds."
  }
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds. Must be less than the interval."
  type        = number
  default     = 5

  validation {
    condition     = var.health_check_timeout >= 2 && var.health_check_timeout <= 120
    error_message = "Health check timeout must be between 2 and 120 seconds."
  }
}

variable "health_check_healthy_threshold" {
  description = "Number of consecutive successful health checks required to mark target healthy."
  type        = number
  default     = 2

  validation {
    condition     = var.health_check_healthy_threshold >= 2 && var.health_check_healthy_threshold <= 10
    error_message = "Healthy threshold must be between 2 and 10."
  }
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive failed health checks required to mark target unhealthy."
  type        = number
  default     = 3

  validation {
    condition     = var.health_check_unhealthy_threshold >= 2 && var.health_check_unhealthy_threshold <= 10
    error_message = "Unhealthy threshold must be between 2 and 10."
  }
}

#------------------------------------------------------------------------------
# Auto-Scaling Configuration
#------------------------------------------------------------------------------

variable "cpu_target_value" {
  description = "Target CPU utilization percentage for auto-scaling. The service scales when average CPU exceeds this threshold."
  type        = number
  default     = 70

  validation {
    condition     = var.cpu_target_value >= 10 && var.cpu_target_value <= 100
    error_message = "CPU target value must be between 10 and 100."
  }
}

variable "scale_out_cooldown" {
  description = "Cooldown period in seconds after a scale-out activity completes before another can start."
  type        = number
  default     = 60

  validation {
    condition     = var.scale_out_cooldown >= 0 && var.scale_out_cooldown <= 3600
    error_message = "Scale-out cooldown must be between 0 and 3600 seconds."
  }
}

variable "scale_in_cooldown" {
  description = "Cooldown period in seconds after a scale-in activity completes before another can start."
  type        = number
  default     = 300

  validation {
    condition     = var.scale_in_cooldown >= 0 && var.scale_in_cooldown <= 3600
    error_message = "Scale-in cooldown must be between 0 and 3600 seconds."
  }
}

#------------------------------------------------------------------------------
# Frontend Configuration
#------------------------------------------------------------------------------

variable "frontend_bucket_name" {
  description = "Name of the S3 bucket for hosting frontend static assets. Must match the CI/CD workflow configuration."
  type        = string
  default     = "langgraph-search-agent-frontend-production"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.frontend_bucket_name))
    error_message = "S3 bucket name must contain only lowercase letters, numbers, hyphens, and periods, and must start and end with a letter or number."
  }

  validation {
    condition     = length(var.frontend_bucket_name) >= 3 && length(var.frontend_bucket_name) <= 63
    error_message = "S3 bucket name must be between 3 and 63 characters."
  }
}

variable "cloudfront_price_class" {
  description = "CloudFront price class determining which edge locations to use. PriceClass_100 uses only US, Canada, and Europe."
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.cloudfront_price_class)
    error_message = "CloudFront price class must be one of: PriceClass_100, PriceClass_200, PriceClass_All."
  }
}

variable "cloudfront_default_ttl" {
  description = "Default TTL in seconds for CloudFront cache when no Cache-Control header is set."
  type        = number
  default     = 86400

  validation {
    condition     = var.cloudfront_default_ttl >= 0 && var.cloudfront_default_ttl <= 31536000
    error_message = "CloudFront default TTL must be between 0 and 31536000 seconds (1 year)."
  }
}

variable "cloudfront_max_ttl" {
  description = "Maximum TTL in seconds for CloudFront cache."
  type        = number
  default     = 31536000

  validation {
    condition     = var.cloudfront_max_ttl >= 0 && var.cloudfront_max_ttl <= 31536000
    error_message = "CloudFront max TTL must be between 0 and 31536000 seconds (1 year)."
  }
}

variable "cloudfront_min_ttl" {
  description = "Minimum TTL in seconds for CloudFront cache."
  type        = number
  default     = 0

  validation {
    condition     = var.cloudfront_min_ttl >= 0 && var.cloudfront_min_ttl <= 31536000
    error_message = "CloudFront min TTL must be between 0 and 31536000 seconds (1 year)."
  }
}

#------------------------------------------------------------------------------
# Networking Configuration
#------------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC. Provides the IP address range for all VPC resources."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "List of availability zones for multi-AZ deployment. Must have at least 2 AZs for high availability."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones are required for high availability."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets. Must be within the VPC CIDR range. One subnet per availability zone."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "At least 2 public subnet CIDRs are required for high availability."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets. Must be within the VPC CIDR range. One subnet per availability zone."
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "At least 2 private subnet CIDRs are required for high availability."
  }
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnet internet access. Required for ECS tasks to pull images and access external APIs."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all availability zones. Cost-effective for non-production environments."
  type        = bool
  default     = false
}

#------------------------------------------------------------------------------
# GitHub OIDC Configuration
#------------------------------------------------------------------------------

variable "github_org" {
  description = "GitHub organization or username owning the repository. Used to configure OIDC trust relationship."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.github_org))
    error_message = "GitHub organization must contain only alphanumeric characters and hyphens."
  }
}

variable "github_repo" {
  description = "GitHub repository name. Used to configure OIDC trust relationship for CI/CD authentication."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._-]+$", var.github_repo))
    error_message = "GitHub repository name must contain only alphanumeric characters, periods, underscores, and hyphens."
  }
}

variable "github_oidc_thumbprint" {
  description = "GitHub Actions OIDC provider thumbprint. Default is the current GitHub thumbprint."
  type        = string
  default     = "6938fd4d98bab03faadb97b34396831e3780aea1"

  validation {
    condition     = can(regex("^[a-f0-9]{40}$", var.github_oidc_thumbprint))
    error_message = "OIDC thumbprint must be a 40-character hexadecimal string."
  }
}

#------------------------------------------------------------------------------
# Database Configuration
#------------------------------------------------------------------------------

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table for storing conversation sessions. Must match the backend application configuration."
  type        = string
  default     = "langgraph-conversations"

  validation {
    condition     = can(regex("^[a-zA-Z0-9._-]+$", var.dynamodb_table_name))
    error_message = "DynamoDB table name must contain only alphanumeric characters, periods, underscores, and hyphens."
  }

  validation {
    condition     = length(var.dynamodb_table_name) >= 3 && length(var.dynamodb_table_name) <= 255
    error_message = "DynamoDB table name must be between 3 and 255 characters."
  }
}

variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode. PAY_PER_REQUEST provides on-demand scaling without capacity planning."
  type        = string
  default     = "PAY_PER_REQUEST"

  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.dynamodb_billing_mode)
    error_message = "DynamoDB billing mode must be either PAY_PER_REQUEST or PROVISIONED."
  }
}

variable "dynamodb_ttl_enabled" {
  description = "Enable TTL (Time to Live) for automatic expiration of old conversation sessions."
  type        = bool
  default     = true
}

variable "dynamodb_ttl_attribute" {
  description = "Name of the TTL attribute for DynamoDB. Items with expired TTL values are automatically deleted."
  type        = string
  default     = "expiration"
}

#------------------------------------------------------------------------------
# Application Configuration
#------------------------------------------------------------------------------

variable "cors_origins" {
  description = "List of allowed CORS origins for the backend API. Use ['*'] to allow all origins in development."
  type        = list(string)
  default     = ["*"]
}

variable "api_url" {
  description = "Base URL for the backend API. Used by the frontend application to make API calls."
  type        = string
  default     = ""
}

#------------------------------------------------------------------------------
# Monitoring Configuration
#------------------------------------------------------------------------------

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs. Longer retention increases storage costs."
  type        = number
  default     = 30

  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch Logs retention period."
  }
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights for detailed ECS monitoring."
  type        = bool
  default     = true
}

variable "enable_execute_command" {
  description = "Enable ECS Exec for debugging containers. Allows running commands in containers via AWS CLI."
  type        = bool
  default     = false
}

#------------------------------------------------------------------------------
# Secrets Configuration
#------------------------------------------------------------------------------

variable "create_secrets" {
  description = "Create Secrets Manager secrets for API keys. Set to false if secrets already exist."
  type        = bool
  default     = true
}

variable "openai_api_key_secret_name" {
  description = "Name of the Secrets Manager secret containing the OpenAI API key."
  type        = string
  default     = "langgraph-search-agent/openai-api-key"
}

variable "tavily_api_key_secret_name" {
  description = "Name of the Secrets Manager secret containing the Tavily API key."
  type        = string
  default     = "langgraph-search-agent/tavily-api-key"
}

#------------------------------------------------------------------------------
# Terraform State Backend Configuration
#------------------------------------------------------------------------------

variable "terraform_state_bucket" {
  description = "S3 bucket name for storing Terraform state files. Must be globally unique."
  type        = string
  default     = "langgraph-search-agent-terraform-state"
}

variable "terraform_state_lock_table" {
  description = "DynamoDB table name for Terraform state locking."
  type        = string
  default     = "langgraph-search-agent-terraform-locks"
}

variable "terraform_state_key" {
  description = "S3 key path for the Terraform state file."
  type        = string
  default     = "state/terraform.tfstate"
}

#------------------------------------------------------------------------------
# ALB Configuration
#------------------------------------------------------------------------------

variable "alb_internal" {
  description = "Set to true to create an internal ALB. Internal ALBs are not accessible from the internet."
  type        = bool
  default     = false
}

variable "alb_idle_timeout" {
  description = "Time in seconds that the connection is allowed to be idle."
  type        = number
  default     = 60

  validation {
    condition     = var.alb_idle_timeout >= 1 && var.alb_idle_timeout <= 4000
    error_message = "ALB idle timeout must be between 1 and 4000 seconds."
  }
}

variable "alb_deletion_protection" {
  description = "Enable deletion protection for the ALB. Prevents accidental deletion via Terraform."
  type        = bool
  default     = false
}

variable "enable_https" {
  description = "Enable HTTPS on the ALB. Requires a valid ACM certificate."
  type        = bool
  default     = false
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS. Required if enable_https is true."
  type        = string
  default     = ""
}

variable "ssl_policy" {
  description = "SSL policy for the HTTPS listener. Only used if enable_https is true."
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}
