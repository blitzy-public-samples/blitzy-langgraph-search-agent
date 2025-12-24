# -----------------------------------------------------------------------------
# Networking Module - Output Values
# LangGraph Search Agent - Terraform Infrastructure
# -----------------------------------------------------------------------------
# Exports network infrastructure identifiers required by other modules including:
# - ecs-fargate module: VPC ID, private subnet IDs, ECS security group ID
# - frontend module: VPC ID for reference
# - Root configuration: All values for CI/CD and monitoring integration
#
# Reference: Agent Action Plan Section 0.4.5 (Module Output Dependencies)
#            Agent Action Plan Section 0.5.1 Group 3 (Networking Module)
# -----------------------------------------------------------------------------

# =============================================================================
# VPC OUTPUTS
# =============================================================================
# These outputs provide VPC identifiers used by all modules requiring
# network attachment. The VPC ID is consumed by ecs-fargate, frontend,
# and any future modules requiring VPC resource association.
# =============================================================================

output "vpc_id" {
  description = <<-EOT
    The ID of the VPC created for the LangGraph Search Agent infrastructure.
    
    Consumed by:
    - ecs-fargate module: For ALB and ECS service VPC attachment
    - frontend module: For potential VPC endpoint configurations
    - monitoring module: For VPC Flow Logs if enabled
    
    Example value: vpc-0abc123def456789
  EOT
  value = aws_vpc.main.id
}

output "vpc_cidr" {
  description = <<-EOT
    The primary CIDR block of the VPC (e.g., 10.0.0.0/16).
    
    Used for:
    - Security group rule definitions referencing the VPC CIDR
    - Network ACL configurations
    - Documentation and troubleshooting
    
    Default: 10.0.0.0/16 (65,536 IP addresses)
  EOT
  value = aws_vpc.main.cidr_block
}

output "vpc_cidr_block" {
  description = <<-EOT
    Alias for vpc_cidr - The primary CIDR block of the VPC.
    Provided for compatibility with modules expecting this naming convention.
  EOT
  value = aws_vpc.main.cidr_block
}

output "vpc_arn" {
  description = <<-EOT
    The ARN of the VPC for IAM policy references.
    
    Used for:
    - IAM resource-based policies scoping access to this VPC
    - CloudWatch Logs resource policies
    - AWS Config rules targeting this VPC
  EOT
  value = aws_vpc.main.arn
}

# =============================================================================
# SUBNET OUTPUTS
# =============================================================================
# Subnet outputs enable proper placement of resources across availability
# zones. Public subnets host the ALB, private subnets host ECS Fargate tasks.
# Reference: Agent Action Plan Section 0.4.4 (VPC Architecture)
# =============================================================================

output "public_subnet_ids" {
  description = <<-EOT
    List of public subnet IDs for ALB placement and internet-facing resources.
    
    Consumed by:
    - ecs-fargate module: For Application Load Balancer placement
    - NAT Gateway placement (already configured in this module)
    
    Public subnets have:
    - Route to Internet Gateway for inbound/outbound internet traffic
    - Public IP assignment enabled for resources
    
    Default configuration:
    - 10.0.1.0/24 in us-east-1a
    - 10.0.2.0/24 in us-east-1b
  EOT
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = <<-EOT
    List of private subnet IDs for ECS Fargate task placement.
    
    Consumed by:
    - ecs-fargate module: For Fargate task network configuration
    
    Private subnets have:
    - Route to NAT Gateway for outbound internet (API calls to OpenAI, Tavily)
    - No public IP assignment (enhanced security)
    - Isolated from direct internet access
    
    Default configuration:
    - 10.0.10.0/24 in us-east-1a
    - 10.0.11.0/24 in us-east-1b
  EOT
  value = aws_subnet.private[*].id
}

output "public_subnet_cidrs" {
  description = <<-EOT
    List of CIDR blocks for public subnets.
    Useful for security group rule definitions and network planning.
  EOT
  value = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidrs" {
  description = <<-EOT
    List of CIDR blocks for private subnets.
    Useful for security group rule definitions and network planning.
  EOT
  value = aws_subnet.private[*].cidr_block
}

output "availability_zones" {
  description = <<-EOT
    List of availability zones where subnets are deployed.
    
    Used by:
    - ecs-fargate module: To understand AZ distribution for task placement
    - Capacity planning and high availability configuration
    
    Default: ["us-east-1a", "us-east-1b"]
  EOT
  value = var.availability_zones
}

# =============================================================================
# SECURITY GROUP OUTPUTS
# =============================================================================
# Security group outputs enable proper traffic rules between ALB and ECS.
# Reference: Agent Action Plan Section 0.4.4 (Network Security)
# - ALB SG: Allows HTTP (80) and HTTPS (443) from internet
# - ECS SG: Allows port 8000 from ALB only, HTTPS egress for API calls
# =============================================================================

output "alb_security_group_id" {
  description = <<-EOT
    Security group ID for the Application Load Balancer.
    
    Consumed by:
    - ecs-fargate module: For ALB security group attachment
    
    Configured rules:
    - Ingress: TCP 80 (HTTP), TCP 443 (HTTPS) from 0.0.0.0/0
    - Egress: All traffic to ECS security group on container port
    
    Reference: Agent Action Plan Section 0.4.4 - ALB Security Rules
  EOT
  value = aws_security_group.alb.id
}

output "alb_security_group_arn" {
  description = <<-EOT
    ARN of the ALB security group for IAM policy references.
  EOT
  value = aws_security_group.alb.arn
}

output "ecs_security_group_id" {
  description = <<-EOT
    Security group ID for ECS Fargate tasks running the backend container.
    
    Consumed by:
    - ecs-fargate module: For ECS service network configuration
    
    Configured rules:
    - Ingress: TCP 8000 from ALB security group only (container port)
    - Egress: TCP 443 to 0.0.0.0/0 for external API calls
      * OpenAI API (api.openai.com)
      * Tavily API (api.tavily.com)
      * AWS APIs (ECR, CloudWatch, Secrets Manager)
    
    Reference: Agent Action Plan Section 0.4.4 - ECS Security Rules
  EOT
  value = aws_security_group.ecs.id
}

output "ecs_security_group_arn" {
  description = <<-EOT
    ARN of the ECS security group for IAM policy references.
  EOT
  value = aws_security_group.ecs.arn
}

# =============================================================================
# INTERNET GATEWAY OUTPUTS
# =============================================================================
# Internet Gateway provides public internet connectivity for resources
# in public subnets (ALB) and is required for NAT Gateway operation.
# =============================================================================

output "internet_gateway_id" {
  description = <<-EOT
    The ID of the Internet Gateway attached to the VPC.
    
    Used for:
    - Public route table configuration (routes 0.0.0.0/0 to IGW)
    - Documentation and troubleshooting
    
    The IGW enables:
    - Inbound traffic from internet to ALB in public subnets
    - Outbound traffic from ALB to internet
    - NAT Gateway internet connectivity
  EOT
  value = aws_internet_gateway.main.id
}

output "internet_gateway_arn" {
  description = <<-EOT
    ARN of the Internet Gateway for resource tagging and policy references.
  EOT
  value = aws_internet_gateway.main.arn
}

# =============================================================================
# NAT GATEWAY OUTPUTS
# =============================================================================
# NAT Gateway enables outbound internet access for ECS Fargate tasks in
# private subnets. Tasks need this for external API calls to OpenAI/Tavily.
# Configuration supports single NAT Gateway (dev/staging) or multi-AZ (prod).
# =============================================================================

output "nat_gateway_ids" {
  description = <<-EOT
    List of NAT Gateway IDs for private subnet outbound internet access.
    
    Used for:
    - Private route table configuration (routes 0.0.0.0/0 to NAT GW)
    - Cost monitoring and capacity planning
    
    Configuration options (controlled by single_nat_gateway variable):
    - Single NAT Gateway: Cost-effective for dev/staging (~$32/month)
    - Multiple NAT Gateways: High availability for production (~$32/month per AZ)
    
    Returns empty list if enable_nat_gateway = false
  EOT
  value = aws_nat_gateway.main[*].id
}

output "nat_gateway_id" {
  description = <<-EOT
    The ID of the primary NAT Gateway (first in the list).
    
    Convenience output for configurations using single NAT Gateway.
    Returns empty string if NAT Gateway is disabled.
    
    Reference: Agent Action Plan Section 0.4.4 - NAT Gateway for private subnets
  EOT
  value = length(aws_nat_gateway.main) > 0 ? aws_nat_gateway.main[0].id : ""
}

output "nat_gateway_public_ips" {
  description = <<-EOT
    List of public IP addresses assigned to NAT Gateways.
    
    Useful for:
    - Whitelisting in external API configurations
    - Network troubleshooting and traffic analysis
    - Security auditing
  EOT
  value = aws_eip.nat[*].public_ip
}

output "nat_gateway_elastic_ip_ids" {
  description = <<-EOT
    List of Elastic IP allocation IDs associated with NAT Gateways.
    
    Used for:
    - Cost tracking (EIPs incur charges when not attached)
    - IP address management
  EOT
  value = aws_eip.nat[*].id
}

# =============================================================================
# ROUTE TABLE OUTPUTS
# =============================================================================
# Route tables control traffic flow within the VPC. Public route table
# directs traffic to IGW, private route tables direct to NAT Gateway.
# =============================================================================

output "public_route_table_id" {
  description = <<-EOT
    The ID of the public route table used by public subnets.
    
    Route configuration:
    - 0.0.0.0/0 -> Internet Gateway (internet access)
    - Local VPC CIDR -> Local (VPC internal routing)
    
    Associated with all public subnets for ALB internet connectivity.
  EOT
  value = aws_route_table.public.id
}

output "public_route_table_arn" {
  description = <<-EOT
    ARN of the public route table for resource tagging and policy references.
  EOT
  value = aws_route_table.public.arn
}

output "private_route_table_ids" {
  description = <<-EOT
    List of private route table IDs used by private subnets.
    
    Route configuration:
    - 0.0.0.0/0 -> NAT Gateway (outbound internet via NAT)
    - Local VPC CIDR -> Local (VPC internal routing)
    
    Number of route tables depends on single_nat_gateway setting:
    - single_nat_gateway = true: One route table for all private subnets
    - single_nat_gateway = false: One route table per AZ (high availability)
    
    Returns empty list if enable_nat_gateway = false
  EOT
  value = aws_route_table.private[*].id
}

output "private_route_table_id" {
  description = <<-EOT
    The ID of the primary private route table (first in the list).
    
    Convenience output for single NAT Gateway configurations.
    Returns empty string if NAT Gateway is disabled.
  EOT
  value = length(aws_route_table.private) > 0 ? aws_route_table.private[0].id : ""
}

# =============================================================================
# COMPUTED NETWORKING SUMMARY
# =============================================================================
# Aggregated output for easy consumption by root module and documentation.
# =============================================================================

output "networking_summary" {
  description = <<-EOT
    Summary object containing all critical networking identifiers.
    
    Provides a single output for modules that need multiple network values.
    Useful for passing to child modules as a single object.
  EOT
  value = {
    vpc_id                  = aws_vpc.main.id
    vpc_cidr                = aws_vpc.main.cidr_block
    public_subnet_ids       = aws_subnet.public[*].id
    private_subnet_ids      = aws_subnet.private[*].id
    alb_security_group_id   = aws_security_group.alb.id
    ecs_security_group_id   = aws_security_group.ecs.id
    internet_gateway_id     = aws_internet_gateway.main.id
    nat_gateway_ids         = aws_nat_gateway.main[*].id
    availability_zones      = var.availability_zones
  }
}

# =============================================================================
# INTEGRATION OUTPUTS FOR CI/CD
# =============================================================================
# Outputs formatted for easy consumption by GitHub Actions workflows
# and other CI/CD tooling that needs network resource references.
# =============================================================================

output "vpc_config_for_cicd" {
  description = <<-EOT
    VPC configuration formatted for CI/CD consumption.
    
    Contains comma-separated lists suitable for shell scripts and
    GitHub Actions workflow consumption without complex parsing.
  EOT
  value = {
    vpc_id                     = aws_vpc.main.id
    public_subnet_ids_csv      = join(",", aws_subnet.public[*].id)
    private_subnet_ids_csv     = join(",", aws_subnet.private[*].id)
    security_group_alb_id      = aws_security_group.alb.id
    security_group_ecs_id      = aws_security_group.ecs.id
  }
}
