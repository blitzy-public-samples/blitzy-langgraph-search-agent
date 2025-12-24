# -----------------------------------------------------------------------------
# ECS Fargate Module - Input Variable Declarations
# -----------------------------------------------------------------------------
# Comprehensive input variable definitions for configuring ECS Fargate resources
# including cluster, service, task definition, ALB, auto-scaling, and networking.
#
# All defaults are aligned with existing CI/CD workflow expectations from
# .github/workflows/backend-deploy.yml to ensure seamless integration.
# -----------------------------------------------------------------------------

# =============================================================================
# PROJECT IDENTIFICATION
# =============================================================================

variable "project_name" {
  description = "Name of the project, used for resource naming and tagging"
  type        = string
  default     = "langgraph-search-agent"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod, production)"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["dev", "staging", "prod", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, production."
  }
}

variable "aws_region" {
  description = "AWS region for resource deployment (us-east-1 required per project constraints)"
  type        = string
  default     = "us-east-1"
}

# =============================================================================
# ECS CLUSTER CONFIGURATION
# =============================================================================

variable "cluster_name" {
  description = "Name of the ECS cluster (must match CI/CD workflow expectations)"
  type        = string
  default     = "langgraph-search-agent-cluster"
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights for enhanced monitoring"
  type        = bool
  default     = false
}

# =============================================================================
# ECS SERVICE CONFIGURATION
# =============================================================================

variable "service_name" {
  description = "Name of the ECS service (must match CI/CD workflow expectations)"
  type        = string
  default     = "langgraph-search-agent-service"
}

variable "desired_count" {
  description = "Desired number of ECS tasks to run in the service"
  type        = number
  default     = 1

  validation {
    condition     = var.desired_count >= 0
    error_message = "Desired count must be a non-negative integer."
  }
}

variable "deployment_minimum_healthy_percent" {
  description = "Minimum percentage of healthy tasks during rolling deployment"
  type        = number
  default     = 50

  validation {
    condition     = var.deployment_minimum_healthy_percent >= 0 && var.deployment_minimum_healthy_percent <= 100
    error_message = "Deployment minimum healthy percent must be between 0 and 100."
  }
}

variable "deployment_maximum_percent" {
  description = "Maximum percentage of tasks during rolling deployment (allows over-provisioning)"
  type        = number
  default     = 200

  validation {
    condition     = var.deployment_maximum_percent >= 100 && var.deployment_maximum_percent <= 400
    error_message = "Deployment maximum percent must be between 100 and 400."
  }
}

variable "health_check_grace_period_seconds" {
  description = "Grace period (seconds) before health checks are evaluated after task start"
  type        = number
  default     = 60

  validation {
    condition     = var.health_check_grace_period_seconds >= 0 && var.health_check_grace_period_seconds <= 7200
    error_message = "Health check grace period must be between 0 and 7200 seconds."
  }
}

# =============================================================================
# TASK DEFINITION CONFIGURATION
# =============================================================================

variable "task_family" {
  description = "Family name for the ECS task definition (must match CI/CD workflow expectations)"
  type        = string
  default     = "langgraph-search-agent-task"
}

variable "task_cpu" {
  description = "CPU units for the Fargate task (valid values: 256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 256

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.task_cpu)
    error_message = "Task CPU must be one of: 256, 512, 1024, 2048, 4096."
  }
}

variable "task_memory" {
  description = "Memory (MiB) for the Fargate task (must be compatible with CPU setting)"
  type        = number
  default     = 512

  validation {
    condition     = var.task_memory >= 512 && var.task_memory <= 30720
    error_message = "Task memory must be between 512 and 30720 MiB."
  }
}

# =============================================================================
# CONTAINER CONFIGURATION
# =============================================================================

variable "container_name" {
  description = "Name of the container within the task definition (must match CI/CD workflow expectations)"
  type        = string
  default     = "langgraph-search-agent-container"
}

variable "container_image" {
  description = "Full ECR repository URL for the container image (e.g., account.dkr.ecr.region.amazonaws.com/repo:tag)"
  type        = string
}

variable "container_port" {
  description = "Port exposed by the container (FastAPI application runs on port 8000)"
  type        = number
  default     = 8000

  validation {
    condition     = var.container_port >= 1 && var.container_port <= 65535
    error_message = "Container port must be a valid port number (1-65535)."
  }
}

# =============================================================================
# APPLICATION ENVIRONMENT CONFIGURATION
# =============================================================================

variable "dynamodb_table_name" {
  description = "DynamoDB table name for conversation persistence (configured but not actively used)"
  type        = string
  default     = "langgraph-conversations"
}

variable "cors_origins" {
  description = "Allowed CORS origins for the API (use specific origins in production)"
  type        = string
  default     = "*"
}

# =============================================================================
# NETWORKING CONFIGURATION
# =============================================================================

variable "vpc_id" {
  description = "VPC ID where ECS resources and ALB will be deployed"
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-z0-9]+$", var.vpc_id))
    error_message = "VPC ID must be a valid AWS VPC ID (e.g., vpc-1234567890abcdef0)."
  }
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the Application Load Balancer"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "At least 2 public subnet IDs are required for ALB high availability."
  }
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS Fargate tasks"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "At least 2 private subnet IDs are required for ECS task high availability."
  }
}

variable "alb_security_group_id" {
  description = "Security group ID for the Application Load Balancer (allows HTTP/HTTPS ingress)"
  type        = string

  validation {
    condition     = can(regex("^sg-[a-z0-9]+$", var.alb_security_group_id))
    error_message = "ALB security group ID must be a valid AWS security group ID (e.g., sg-1234567890abcdef0)."
  }
}

variable "ecs_security_group_id" {
  description = "Security group ID for ECS Fargate tasks (allows traffic from ALB on container port)"
  type        = string

  validation {
    condition     = can(regex("^sg-[a-z0-9]+$", var.ecs_security_group_id))
    error_message = "ECS security group ID must be a valid AWS security group ID (e.g., sg-1234567890abcdef0)."
  }
}

# =============================================================================
# IAM ROLE CONFIGURATION
# =============================================================================

variable "execution_role_arn" {
  description = "ARN of the ECS task execution IAM role (for ECR pull, CloudWatch logs, Secrets Manager)"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]+:role/.+$", var.execution_role_arn))
    error_message = "Execution role ARN must be a valid IAM role ARN."
  }
}

variable "task_role_arn" {
  description = "ARN of the ECS task IAM role (for container runtime permissions like DynamoDB access)"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]+:role/.+$", var.task_role_arn))
    error_message = "Task role ARN must be a valid IAM role ARN."
  }
}

# =============================================================================
# SECRETS MANAGER CONFIGURATION
# =============================================================================

variable "openai_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the OPENAI_API_KEY"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:secretsmanager:[a-z0-9-]+:[0-9]+:secret:.+$", var.openai_secret_arn))
    error_message = "OpenAI secret ARN must be a valid Secrets Manager secret ARN."
  }
}

variable "tavily_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the TAVILY_API_KEY"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:secretsmanager:[a-z0-9-]+:[0-9]+:secret:.+$", var.tavily_secret_arn))
    error_message = "Tavily secret ARN must be a valid Secrets Manager secret ARN."
  }
}

# =============================================================================
# CLOUDWATCH LOGGING CONFIGURATION
# =============================================================================

variable "log_group_name" {
  description = "CloudWatch log group name for container logs"
  type        = string
  default     = "/ecs/langgraph-search-agent"
}

variable "log_retention_days" {
  description = "Number of days to retain container logs in CloudWatch"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch retention value."
  }
}

# =============================================================================
# APPLICATION LOAD BALANCER CONFIGURATION
# =============================================================================

variable "alb_name" {
  description = "Name of the Application Load Balancer"
  type        = string
  default     = "langgraph-search-agent-alb"

  validation {
    condition     = length(var.alb_name) <= 32
    error_message = "ALB name must be 32 characters or less."
  }
}

variable "alb_internal" {
  description = "Whether the ALB is internal (private) or internet-facing (public)"
  type        = bool
  default     = false
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for the ALB (recommended for production)"
  type        = bool
  default     = false
}

variable "idle_timeout" {
  description = "Idle timeout (seconds) for ALB connections"
  type        = number
  default     = 60

  validation {
    condition     = var.idle_timeout >= 1 && var.idle_timeout <= 4000
    error_message = "ALB idle timeout must be between 1 and 4000 seconds."
  }
}

# =============================================================================
# TARGET GROUP AND HEALTH CHECK CONFIGURATION
# =============================================================================

variable "target_group_name" {
  description = "Name of the ALB target group"
  type        = string
  default     = "langgraph-search-agent-tg"

  validation {
    condition     = length(var.target_group_name) <= 32
    error_message = "Target group name must be 32 characters or less."
  }
}

variable "health_check_path" {
  description = "HTTP path for ALB health checks (must return 200 OK when healthy)"
  type        = string
  default     = "/health"
}

variable "health_check_interval" {
  description = "Interval (seconds) between health checks"
  type        = number
  default     = 30

  validation {
    condition     = var.health_check_interval >= 5 && var.health_check_interval <= 300
    error_message = "Health check interval must be between 5 and 300 seconds."
  }
}

variable "health_check_timeout" {
  description = "Timeout (seconds) for health check responses"
  type        = number
  default     = 5

  validation {
    condition     = var.health_check_timeout >= 2 && var.health_check_timeout <= 120
    error_message = "Health check timeout must be between 2 and 120 seconds."
  }
}

variable "health_check_healthy_threshold" {
  description = "Number of consecutive successful health checks to mark target healthy"
  type        = number
  default     = 2

  validation {
    condition     = var.health_check_healthy_threshold >= 2 && var.health_check_healthy_threshold <= 10
    error_message = "Healthy threshold must be between 2 and 10."
  }
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive failed health checks to mark target unhealthy"
  type        = number
  default     = 3

  validation {
    condition     = var.health_check_unhealthy_threshold >= 2 && var.health_check_unhealthy_threshold <= 10
    error_message = "Unhealthy threshold must be between 2 and 10."
  }
}

variable "health_check_matcher" {
  description = "HTTP response codes to consider healthy (e.g., '200' or '200-299')"
  type        = string
  default     = "200"
}

# =============================================================================
# AUTO-SCALING CONFIGURATION
# =============================================================================

variable "enable_autoscaling" {
  description = "Enable auto-scaling for the ECS service"
  type        = bool
  default     = true
}

variable "min_capacity" {
  description = "Minimum number of ECS tasks for auto-scaling"
  type        = number
  default     = 1

  validation {
    condition     = var.min_capacity >= 0
    error_message = "Minimum capacity must be a non-negative integer."
  }
}

variable "max_capacity" {
  description = "Maximum number of ECS tasks for auto-scaling"
  type        = number
  default     = 10

  validation {
    condition     = var.max_capacity >= 1
    error_message = "Maximum capacity must be at least 1."
  }
}

variable "cpu_target_value" {
  description = "Target CPU utilization percentage for auto-scaling (triggers scale-out when exceeded)"
  type        = number
  default     = 70

  validation {
    condition     = var.cpu_target_value >= 1 && var.cpu_target_value <= 100
    error_message = "CPU target value must be between 1 and 100 percent."
  }
}

variable "memory_target_value" {
  description = "Target memory utilization percentage for auto-scaling (optional, 0 to disable)"
  type        = number
  default     = 0

  validation {
    condition     = var.memory_target_value >= 0 && var.memory_target_value <= 100
    error_message = "Memory target value must be between 0 and 100 percent."
  }
}

variable "scale_in_cooldown" {
  description = "Cooldown period (seconds) after a scale-in event before another can occur"
  type        = number
  default     = 300

  validation {
    condition     = var.scale_in_cooldown >= 0 && var.scale_in_cooldown <= 3600
    error_message = "Scale-in cooldown must be between 0 and 3600 seconds."
  }
}

variable "scale_out_cooldown" {
  description = "Cooldown period (seconds) after a scale-out event before another can occur"
  type        = number
  default     = 60

  validation {
    condition     = var.scale_out_cooldown >= 0 && var.scale_out_cooldown <= 3600
    error_message = "Scale-out cooldown must be between 0 and 3600 seconds."
  }
}

# =============================================================================
# RESOURCE TAGGING
# =============================================================================

variable "tags" {
  description = "Common tags to apply to all resources created by this module"
  type        = map(string)
  default     = {}
}
