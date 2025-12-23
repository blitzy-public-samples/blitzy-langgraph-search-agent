# -----------------------------------------------------------------------------
# Local Values for LangGraph Search Agent Infrastructure
# -----------------------------------------------------------------------------
# This file defines computed variables, common resource tags, naming conventions,
# and reusable expressions used throughout the Terraform configuration.
#
# Key features:
# - Common tags applied to all AWS resources for consistent labeling
# - Environment-specific configuration maps for dev/staging/prod
# - Computed resource names following {project}-{component} pattern
# - VPC CIDR block calculations for subnet allocation
# -----------------------------------------------------------------------------

locals {
  # ---------------------------------------------------------------------------
  # Common Tags
  # ---------------------------------------------------------------------------
  # Applied to all resources for consistent labeling and cost allocation.
  # These tags enable resource tracking, environment identification, and
  # cost management across the infrastructure.
  #
  # Tag descriptions:
  # - Project: Identifies resources belonging to this application
  # - Environment: Distinguishes dev/staging/prod resources
  # - ManagedBy: Indicates IaC management for audit compliance
  # - Region: Captures deployment region for multi-region awareness
  # ---------------------------------------------------------------------------
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Region      = var.aws_region
  }

  # ---------------------------------------------------------------------------
  # Resource Naming Convention
  # ---------------------------------------------------------------------------
  # Standard prefix pattern: {project_name}-{environment}
  # Examples:
  # - langgraph-search-agent-production
  # - langgraph-search-agent-dev
  # - langgraph-search-agent-staging
  # ---------------------------------------------------------------------------
  name_prefix = "${var.project_name}-${var.environment}"

  # ---------------------------------------------------------------------------
  # Environment-Specific Configuration
  # ---------------------------------------------------------------------------
  # Defines resource sizing and scaling parameters per environment.
  # These values align with Section 0.7.3 Performance and Scalability
  # requirements from the Agent Action Plan.
  #
  # Resource sizing rationale:
  # - Development: Minimal resources for cost optimization, single AZ
  # - Staging: Moderate resources for realistic testing, single AZ
  # - Production: Full capacity with high availability, multi-AZ NAT
  #
  # Auto-scaling configuration:
  # - Scale-out on 70% CPU target (configurable)
  # - Scale-in cooldown longer in production (300s) for stability
  # ---------------------------------------------------------------------------
  environment_config = {
    dev = {
      # Minimal capacity for development workloads
      min_capacity  = 1
      max_capacity  = 2
      desired_count = 1
      # Fargate CPU units: 256 = 0.25 vCPU
      cpu = 256
      # Fargate memory in MB: 512MB minimum for 256 CPU units
      memory = 512
      # Single AZ NAT Gateway to minimize costs
      multi_az_nat = false
      # Scale-in cooldown in seconds (faster in dev)
      scale_in_cooldown = 120
      # Scale-out cooldown in seconds
      scale_out_cooldown = 60
      # Log retention in days (shorter in dev)
      log_retention_days = 7
      # Health check grace period in seconds
      health_check_grace_period = 60
    }
    staging = {
      # Moderate capacity for pre-production testing
      min_capacity  = 1
      max_capacity  = 3
      desired_count = 1
      # Fargate CPU units: 512 = 0.5 vCPU
      cpu = 512
      # Fargate memory in MB: 1024MB = 1GB
      memory = 1024
      # Single AZ NAT Gateway for cost efficiency
      multi_az_nat = false
      # Scale-in cooldown in seconds
      scale_in_cooldown = 120
      # Scale-out cooldown in seconds
      scale_out_cooldown = 60
      # Log retention in days
      log_retention_days = 14
      # Health check grace period in seconds
      health_check_grace_period = 120
    }
    prod = {
      # High availability production configuration
      min_capacity  = 2
      max_capacity  = 10
      desired_count = 2
      # Fargate CPU units: 1024 = 1 vCPU
      cpu = 1024
      # Fargate memory in MB: 2048MB = 2GB
      memory = 2048
      # Multi-AZ NAT Gateway for high availability
      multi_az_nat = true
      # Longer scale-in cooldown to prevent flapping
      scale_in_cooldown = 300
      # Scale-out cooldown in seconds
      scale_out_cooldown = 60
      # Log retention in days (longer for compliance)
      log_retention_days = 30
      # Health check grace period in seconds
      health_check_grace_period = 180
    }
    # Production alias for backwards compatibility
    production = {
      min_capacity              = 2
      max_capacity              = 10
      desired_count             = 2
      cpu                       = 1024
      memory                    = 2048
      multi_az_nat              = true
      scale_in_cooldown         = 300
      scale_out_cooldown        = 60
      log_retention_days        = 30
      health_check_grace_period = 180
    }
  }

  # ---------------------------------------------------------------------------
  # Current Environment Configuration
  # ---------------------------------------------------------------------------
  # Retrieves the configuration map for the currently selected environment.
  # This allows modules to reference local.current_env_config.cpu instead of
  # local.environment_config[var.environment].cpu for cleaner code.
  # ---------------------------------------------------------------------------
  current_env_config = local.environment_config[var.environment]

  # ---------------------------------------------------------------------------
  # Computed Resource Names
  # ---------------------------------------------------------------------------
  # Resource names following the pattern from existing CI/CD workflows:
  # - ECR Repository: langgraph-search-agent-backend
  # - ECS Cluster: langgraph-search-agent-cluster
  # - ECS Service: langgraph-search-agent-service
  # - ECS Task Definition: langgraph-search-agent-task
  #
  # The coalesce() function allows explicit override via variables while
  # providing sensible defaults based on project name.
  # ---------------------------------------------------------------------------
  
  # ECR repository name for container images
  # Default: {project_name}-backend (e.g., langgraph-search-agent-backend)
  ecr_repository_name = coalesce(var.ecr_repository_name, "${var.project_name}-backend")
  
  # ECS cluster name for container orchestration
  # Default: {project_name}-cluster (e.g., langgraph-search-agent-cluster)
  ecs_cluster_name = coalesce(var.ecs_cluster_name, "${var.project_name}-cluster")
  
  # ECS service name for the backend application
  # Default: {project_name}-service (e.g., langgraph-search-agent-service)
  ecs_service_name = coalesce(var.ecs_service_name, "${var.project_name}-service")
  
  # ECS task definition name
  # Default: {project_name}-task (e.g., langgraph-search-agent-task)
  ecs_task_name = coalesce(var.ecs_task_name, "${var.project_name}-task")
  
  # Container name within the ECS task definition
  # Default: {project_name}-container (e.g., langgraph-search-agent-container)
  container_name = coalesce(var.container_name, "${var.project_name}-container")

  # ---------------------------------------------------------------------------
  # Frontend Resource Names
  # ---------------------------------------------------------------------------
  # S3 bucket and CloudFront naming conventions
  # ---------------------------------------------------------------------------
  
  # Frontend S3 bucket name
  # Default: {project_name}-frontend-{environment}
  # Production example: langgraph-search-agent-frontend-production
  frontend_bucket_name = coalesce(var.frontend_bucket_name, "${var.project_name}-frontend-${var.environment}")

  # ---------------------------------------------------------------------------
  # Networking Resource Names
  # ---------------------------------------------------------------------------
  # VPC and networking component naming
  # ---------------------------------------------------------------------------
  
  # VPC name
  vpc_name = "${var.project_name}-vpc"
  
  # Internet Gateway name
  igw_name = "${var.project_name}-igw"
  
  # NAT Gateway name prefix
  nat_gw_name_prefix = "${var.project_name}-nat"
  
  # Application Load Balancer name
  alb_name = "${var.project_name}-alb"
  
  # Target group name
  target_group_name = "${var.project_name}-tg"
  
  # Security group names
  alb_security_group_name = "${var.project_name}-alb-sg"
  ecs_security_group_name = "${var.project_name}-ecs-sg"

  # ---------------------------------------------------------------------------
  # VPC CIDR Block Calculations
  # ---------------------------------------------------------------------------
  # Computes public and private subnet CIDR blocks based on the VPC CIDR.
  #
  # With VPC CIDR 10.0.0.0/16 and 2 availability zones:
  # - Public subnets: 10.0.1.0/24, 10.0.2.0/24 (256 IPs each)
  # - Private subnets: 10.0.10.0/24, 10.0.11.0/24 (256 IPs each)
  #
  # The cidrsubnet function splits the VPC CIDR:
  # - newbits = 8: Creates /24 subnets from a /16 VPC
  # - netnum: i + 1 for public (1, 2, ...), i + 10 for private (10, 11, ...)
  # ---------------------------------------------------------------------------
  
  # Public subnet CIDR blocks (for ALB, NAT Gateway)
  # Example with 10.0.0.0/16: [10.0.1.0/24, 10.0.2.0/24]
  public_subnet_cidrs = [
    for i, az in var.availability_zones : cidrsubnet(var.vpc_cidr, 8, i + 1)
  ]
  
  # Private subnet CIDR blocks (for ECS Fargate tasks)
  # Example with 10.0.0.0/16: [10.0.10.0/24, 10.0.11.0/24]
  private_subnet_cidrs = [
    for i, az in var.availability_zones : cidrsubnet(var.vpc_cidr, 8, i + 10)
  ]

  # ---------------------------------------------------------------------------
  # Monitoring Resource Names
  # ---------------------------------------------------------------------------
  # CloudWatch log group and alarm naming
  # ---------------------------------------------------------------------------
  
  # CloudWatch log group name for ECS container logs
  # Pattern: /ecs/{project_name}
  log_group_name = "/ecs/${var.project_name}"
  
  # CloudWatch alarm name prefix
  alarm_name_prefix = "${var.project_name}-${var.environment}"

  # ---------------------------------------------------------------------------
  # IAM Resource Names
  # ---------------------------------------------------------------------------
  # IAM role and policy naming conventions
  # ---------------------------------------------------------------------------
  
  # ECS task execution role name
  ecs_task_execution_role_name = "${var.project_name}-ecs-task-execution-role"
  
  # ECS task role name
  ecs_task_role_name = "${var.project_name}-ecs-task-role"
  
  # GitHub Actions OIDC role name
  github_actions_role_name = "${var.project_name}-github-actions-role"

  # ---------------------------------------------------------------------------
  # Secrets Manager Resource Names
  # ---------------------------------------------------------------------------
  # Secret naming conventions for API keys
  # ---------------------------------------------------------------------------
  
  # OpenAI API key secret name
  openai_secret_name = "${var.project_name}/${var.environment}/openai-api-key"
  
  # Tavily API key secret name
  tavily_secret_name = "${var.project_name}/${var.environment}/tavily-api-key"

  # ---------------------------------------------------------------------------
  # Database Resource Names
  # ---------------------------------------------------------------------------
  # DynamoDB table naming
  # ---------------------------------------------------------------------------
  
  # DynamoDB table name (matches backend/app/config.py)
  dynamodb_table_name = coalesce(var.dynamodb_table_name, "langgraph-conversations")

  # ---------------------------------------------------------------------------
  # Terraform State Backend Resource Names
  # ---------------------------------------------------------------------------
  # S3 bucket and DynamoDB table for Terraform state management
  # ---------------------------------------------------------------------------
  
  # Terraform state S3 bucket name
  terraform_state_bucket = "${var.project_name}-terraform-state"
  
  # Terraform state lock DynamoDB table name
  terraform_lock_table = "${var.project_name}-terraform-locks"

  # ---------------------------------------------------------------------------
  # Auto-Scaling Configuration
  # ---------------------------------------------------------------------------
  # Merged auto-scaling settings combining environment defaults with overrides
  # ---------------------------------------------------------------------------
  
  # Final auto-scaling configuration (environment defaults with variable overrides)
  autoscaling_config = {
    min_capacity       = coalesce(var.min_capacity, local.current_env_config.min_capacity)
    max_capacity       = coalesce(var.max_capacity, local.current_env_config.max_capacity)
    desired_count      = coalesce(var.desired_count, local.current_env_config.desired_count)
    cpu                = coalesce(var.cpu, local.current_env_config.cpu)
    memory             = coalesce(var.memory, local.current_env_config.memory)
    scale_in_cooldown  = local.current_env_config.scale_in_cooldown
    scale_out_cooldown = local.current_env_config.scale_out_cooldown
  }

  # ---------------------------------------------------------------------------
  # Container Configuration
  # ---------------------------------------------------------------------------
  # Container runtime settings for ECS task definition
  # ---------------------------------------------------------------------------
  
  # Container port (FastAPI default)
  container_port = coalesce(var.container_port, 8000)
  
  # Health check path (FastAPI health endpoint)
  health_check_path = coalesce(var.health_check_path, "/health")
  
  # Health check configuration for target group
  health_check_config = {
    enabled             = true
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = local.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200"
  }

  # ---------------------------------------------------------------------------
  # Availability Zones
  # ---------------------------------------------------------------------------
  # Processed list of availability zones for subnet distribution
  # ---------------------------------------------------------------------------
  
  # Number of availability zones to use
  az_count = length(var.availability_zones)
  
  # Map of availability zone index to name for resource naming
  az_map = {
    for i, az in var.availability_zones : i => az
  }
}
