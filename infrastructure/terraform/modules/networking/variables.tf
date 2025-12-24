# -----------------------------------------------------------------------------
# Networking Module - Input Variables
# LangGraph Search Agent - Terraform Infrastructure
# -----------------------------------------------------------------------------
# This file declares all input variables for the networking module, which
# provisions VPC, subnets, internet gateway, NAT gateway, route tables, and
# security groups for the LangGraph Search Agent application.
#
# Reference: Agent Action Plan Section 0.4.4 (Network Integration)
#            Agent Action Plan Section 0.5.1 Group 3 (Networking Module)
# -----------------------------------------------------------------------------

# =============================================================================
# PROJECT IDENTIFICATION VARIABLES
# =============================================================================

variable "project_name" {
  description = <<-EOT
    Project name used for resource naming convention.
    All resources will be named with the pattern: {project_name}-{component}
    Example: langgraph-search-agent-vpc, langgraph-search-agent-alb-sg
  EOT
  type        = string

  validation {
    condition     = length(var.project_name) > 0 && length(var.project_name) <= 32
    error_message = "Project name must be between 1 and 32 characters."
  }

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = <<-EOT
    Deployment environment identifier used for resource tagging and
    environment-specific configuration. Must be one of: dev, staging, prod.
    This value is used in the common_tags applied to all resources.
  EOT
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

# =============================================================================
# VPC CONFIGURATION VARIABLES
# =============================================================================

variable "vpc_cidr" {
  description = <<-EOT
    CIDR block for the VPC. Default is 10.0.0.0/16 which provides
    65,536 IP addresses, suitable for the LangGraph Search Agent deployment.
    The VPC will be created in us-east-1 region as per requirements.
    
    Reference: Agent Action Plan Section 0.4.4 - VPC CIDR 10.0.0.0/16
  EOT
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block (e.g., 10.0.0.0/16)."
  }

  validation {
    condition     = tonumber(split("/", var.vpc_cidr)[1]) >= 16 && tonumber(split("/", var.vpc_cidr)[1]) <= 28
    error_message = "VPC CIDR block size must be between /16 and /28."
  }
}

variable "enable_dns_hostnames" {
  description = <<-EOT
    Enable DNS hostnames in the VPC. Required for ECS Fargate tasks
    to resolve service discovery endpoints and external APIs.
  EOT
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = <<-EOT
    Enable DNS support in the VPC. Required for internal DNS resolution
    within the VPC for ECS services and ALB endpoints.
  EOT
  type        = bool
  default     = true
}

# =============================================================================
# AVAILABILITY ZONE CONFIGURATION
# =============================================================================

variable "availability_zones" {
  description = <<-EOT
    List of availability zones for multi-AZ deployment.
    Default uses us-east-1a and us-east-1b for high availability.
    At least 2 AZs are required for ALB and ECS service redundancy.
    
    Reference: Agent Action Plan Section 0.4.4 - Multi-AZ deployment
  EOT
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones are required for high availability deployment."
  }

  validation {
    condition     = length(var.availability_zones) == length(distinct(var.availability_zones))
    error_message = "Availability zones must be unique - no duplicates allowed."
  }
}

# =============================================================================
# SUBNET CONFIGURATION VARIABLES
# =============================================================================

variable "public_subnet_cidrs" {
  description = <<-EOT
    CIDR blocks for public subnets where the Application Load Balancer
    will be deployed. One subnet per availability zone is required.
    Public subnets have routes to the Internet Gateway for inbound traffic.
    
    Default: 10.0.1.0/24 (us-east-1a), 10.0.2.0/24 (us-east-1b)
    Reference: Agent Action Plan Section 0.4.4 - Public Subnets
  EOT
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "At least 2 public subnet CIDRs are required for ALB high availability."
  }

  validation {
    condition     = alltrue([for cidr in var.public_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "All public subnet CIDRs must be valid IPv4 CIDR blocks."
  }
}

variable "private_subnet_cidrs" {
  description = <<-EOT
    CIDR blocks for private subnets where ECS Fargate tasks will run.
    One subnet per availability zone is required. Private subnets
    route outbound traffic through NAT Gateway for external API access
    (OpenAI, Tavily) while remaining inaccessible from the internet.
    
    Default: 10.0.10.0/24 (us-east-1a), 10.0.11.0/24 (us-east-1b)
    Reference: Agent Action Plan Section 0.4.4 - Private Subnets
  EOT
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "At least 2 private subnet CIDRs are required for ECS task high availability."
  }

  validation {
    condition     = alltrue([for cidr in var.private_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "All private subnet CIDRs must be valid IPv4 CIDR blocks."
  }
}

# =============================================================================
# NAT GATEWAY CONFIGURATION
# =============================================================================

variable "enable_nat_gateway" {
  description = <<-EOT
    Enable NAT Gateway for private subnet internet access.
    Required for ECS Fargate tasks to reach external APIs (OpenAI, Tavily).
    Set to false only for isolated development environments.
  EOT
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = <<-EOT
    Use a single NAT Gateway for all availability zones (cost-effective).
    Set to true for dev/staging environments to reduce costs.
    Set to false for production to ensure high availability across AZs.
    
    Cost consideration:
    - Single NAT Gateway: ~$32/month + data processing
    - Multiple NAT Gateways: ~$32/month per AZ + data processing
  EOT
  type        = bool
  default     = true
}

# =============================================================================
# CONTAINER AND SECURITY CONFIGURATION
# =============================================================================

variable "container_port" {
  description = <<-EOT
    Port number the backend container listens on.
    Default is 8000 which matches the FastAPI application exposed in
    the backend Dockerfile (EXPOSE 8000) and uvicorn server configuration.
    
    This port is used to configure:
    - ECS security group inbound rules (from ALB)
    - ALB target group health check
    - ECS task definition port mappings
    
    Reference: backend/Dockerfile EXPOSE 8000
  EOT
  type        = number
  default     = 8000

  validation {
    condition     = var.container_port > 0 && var.container_port <= 65535
    error_message = "Container port must be a valid port number between 1 and 65535."
  }

  validation {
    condition     = var.container_port >= 1024 || var.container_port == 80 || var.container_port == 443
    error_message = "Container port should be >= 1024 (unprivileged) or a standard HTTP/HTTPS port."
  }
}

variable "alb_ingress_cidr_blocks" {
  description = <<-EOT
    CIDR blocks allowed to access the Application Load Balancer.
    Default allows all IPv4 addresses (0.0.0.0/0) for public API access.
    Restrict to specific CIDR blocks for internal deployments.
  EOT
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = alltrue([for cidr in var.alb_ingress_cidr_blocks : can(cidrnetmask(cidr))])
    error_message = "All ALB ingress CIDR blocks must be valid IPv4 CIDR notation."
  }
}

variable "enable_https" {
  description = <<-EOT
    Enable HTTPS (port 443) on the ALB security group.
    Set to true when using ACM certificate for SSL termination.
    Default is true to support secure communications.
  EOT
  type        = bool
  default     = true
}

# =============================================================================
# RESOURCE TAGGING
# =============================================================================

variable "tags" {
  description = <<-EOT
    Common tags to apply to all networking resources.
    These tags are merged with module-specific tags.
    
    Expected tags from root module:
    - Project: langgraph-search-agent
    - Environment: dev/staging/prod
    - ManagedBy: terraform
    - Region: us-east-1
    
    Reference: Agent Action Plan Section 0.3.6 - Resource Tagging Standard
  EOT
  type        = map(string)
  default     = {}
}
