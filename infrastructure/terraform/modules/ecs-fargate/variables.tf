# -----------------------------------------------------------------------------
# ECS Fargate Module - Input Variables
# -----------------------------------------------------------------------------
# Variables for configuring ECS cluster, service, task definition, and ALB.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# General Configuration
# -----------------------------------------------------------------------------
variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, production)"
  type        = string
}

variable "aws_region" {
  description = "AWS region for the deployment"
  type        = string
  default     = "us-east-1"
}

# -----------------------------------------------------------------------------
# Cluster Configuration
# -----------------------------------------------------------------------------
variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "enable_container_insights" {
  description = "Whether to enable Container Insights for the ECS cluster"
  type        = bool
  default     = false
}

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "task_family" {
  description = "Family name of the ECS task definition"
  type        = string
}

# -----------------------------------------------------------------------------
# Container Configuration
# -----------------------------------------------------------------------------
variable "container_name" {
  description = "Name of the container in the task definition"
  type        = string
  default     = "backend"
}

variable "container_image" {
  description = "Docker image URL for the container (from ECR)"
  type        = string
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 8000
}

variable "task_cpu" {
  description = "CPU units for the task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memory (MiB) for the task"
  type        = number
  default     = 512
}

# -----------------------------------------------------------------------------
# Service Configuration
# -----------------------------------------------------------------------------
variable "desired_count" {
  description = "Desired number of tasks running in the service"
  type        = number
  default     = 1
}

variable "deployment_minimum_healthy_percent" {
  description = "Minimum percentage of healthy tasks during deployment"
  type        = number
  default     = 50
}

variable "deployment_maximum_percent" {
  description = "Maximum percentage of tasks during deployment"
  type        = number
  default     = 200
}

variable "health_check_grace_period_seconds" {
  description = "Grace period in seconds before health checks are evaluated"
  type        = number
  default     = 60
}

# -----------------------------------------------------------------------------
# Auto Scaling Configuration
# -----------------------------------------------------------------------------
variable "min_capacity" {
  description = "Minimum number of tasks for auto-scaling"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of tasks for auto-scaling"
  type        = number
  default     = 10
}

variable "cpu_target_value" {
  description = "Target CPU utilization percentage for auto-scaling"
  type        = number
  default     = 70
}

variable "scale_out_cooldown" {
  description = "Cooldown period (seconds) after scale-out"
  type        = number
  default     = 60
}

variable "scale_in_cooldown" {
  description = "Cooldown period (seconds) after scale-in"
  type        = number
  default     = 300
}

# -----------------------------------------------------------------------------
# Networking Configuration
# -----------------------------------------------------------------------------
variable "vpc_id" {
  description = "VPC ID where ECS resources will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID for the Application Load Balancer"
  type        = string
}

variable "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

# -----------------------------------------------------------------------------
# IAM Configuration
# -----------------------------------------------------------------------------
variable "execution_role_arn" {
  description = "ARN of the ECS task execution IAM role"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the ECS task IAM role"
  type        = string
}

# -----------------------------------------------------------------------------
# Secrets Configuration
# -----------------------------------------------------------------------------
variable "openai_secret_arn" {
  description = "ARN of the OpenAI API key secret in Secrets Manager"
  type        = string
}

variable "tavily_secret_arn" {
  description = "ARN of the Tavily API key secret in Secrets Manager"
  type        = string
}

# -----------------------------------------------------------------------------
# Logging Configuration
# -----------------------------------------------------------------------------
variable "log_group_name" {
  description = "CloudWatch log group name for container logs"
  type        = string
}

# -----------------------------------------------------------------------------
# Application Configuration
# -----------------------------------------------------------------------------
variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table for conversation persistence"
  type        = string
  default     = "langgraph-conversations"
}

variable "cors_origins" {
  description = "Allowed CORS origins for the backend"
  type        = string
  default     = "*"
}

# -----------------------------------------------------------------------------
# ALB Configuration
# -----------------------------------------------------------------------------
variable "alb_name" {
  description = "Name of the Application Load Balancer"
  type        = string
  default     = ""
}

variable "enable_deletion_protection" {
  description = "Whether to enable deletion protection on the ALB"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Health Check Configuration
# -----------------------------------------------------------------------------
variable "health_check_path" {
  description = "Path for ALB health checks"
  type        = string
  default     = "/health"
}

variable "health_check_interval" {
  description = "Interval between health checks (seconds)"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Timeout for health checks (seconds)"
  type        = number
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "Number of consecutive successful checks to mark healthy"
  type        = number
  default     = 2
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive failed checks to mark unhealthy"
  type        = number
  default     = 3
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
