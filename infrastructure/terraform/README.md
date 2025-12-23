# LangGraph Search Agent - Terraform Infrastructure

This directory contains the Terraform configuration for provisioning AWS infrastructure for the LangGraph Search Agent application. The infrastructure supports a FastAPI backend running on ECS Fargate and a React frontend hosted on S3 with CloudFront CDN distribution.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Directory Structure](#directory-structure)
- [Quick Start](#quick-start)
- [State Backend Bootstrap](#state-backend-bootstrap)
- [Module Documentation](#module-documentation)
- [Environment Deployment](#environment-deployment)
- [CI/CD Integration](#cicd-integration)
- [Resource Naming Convention](#resource-naming-convention)
- [Resource Tagging](#resource-tagging)
- [Security Considerations](#security-considerations)
- [Outputs Reference](#outputs-reference)
- [Troubleshooting](#troubleshooting)

## Prerequisites

Before using this Terraform configuration, ensure you have the following installed and configured:

### Required Tools

| Tool | Minimum Version | Purpose |
|------|-----------------|---------|
| Terraform CLI | >= 1.5.0 | Infrastructure provisioning |
| AWS CLI | >= 2.0 | AWS credential configuration and manual operations |
| Git | >= 2.0 | Version control |

### AWS Account Requirements

- An active AWS account with billing enabled
- IAM permissions to create the following resources:
  - ECR repositories
  - ECS clusters, services, and task definitions
  - VPC, subnets, internet gateways, NAT gateways
  - Application Load Balancers and target groups
  - S3 buckets
  - CloudFront distributions
  - IAM roles and policies
  - Secrets Manager secrets
  - CloudWatch log groups
  - DynamoDB tables

### GitHub Requirements (for CI/CD)

- GitHub repository with Actions enabled
- Repository secrets configured for API keys (OPENAI_API_KEY, TAVILY_API_KEY)
- Write access to configure OIDC authentication

### Installation Commands

```bash
# Install Terraform using tfenv (recommended)
brew install tfenv
tfenv install 1.5.0
tfenv use 1.5.0

# Or install directly
brew install terraform

# Install AWS CLI
brew install awscli

# Verify installations
terraform version  # Should show >= 1.5.0
aws --version      # Should show >= 2.0
```

## Directory Structure

```
infrastructure/terraform/
├── main.tf                     # Root module orchestrating all child modules
├── variables.tf                # Input variable declarations
├── outputs.tf                  # Output values for CI/CD consumption
├── backend.tf                  # S3 + DynamoDB state backend configuration
├── versions.tf                 # Terraform and provider version constraints
├── locals.tf                   # Common tags and computed values
├── terraform.tfvars.example    # Example variable values template
├── .terraform-version          # Terraform version for tfenv
├── README.md                   # This documentation file
│
├── modules/                    # Reusable Terraform modules
│   ├── ecr/                    # ECR container registry
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── networking/             # VPC, subnets, security groups
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── ecs-fargate/            # ECS cluster, service, task definition, ALB
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── frontend/               # S3 bucket + CloudFront distribution
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── storage/                # S3 buckets for state and logs
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── database/               # DynamoDB table
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── monitoring/             # CloudWatch log groups and alarms
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── iam/                    # IAM roles for ECS and GitHub Actions
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── secrets/                # Secrets Manager resources
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
└── environments/               # Environment-specific configurations
    ├── dev/
    │   ├── main.tf
    │   └── terraform.tfvars
    ├── staging/
    │   ├── main.tf
    │   └── terraform.tfvars
    └── prod/
        ├── main.tf
        └── terraform.tfvars
```

## Quick Start

### 1. Configure AWS Credentials

```bash
# Configure AWS CLI with your credentials
aws configure

# Or export environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION="us-east-1"

# Verify AWS access
aws sts get-caller-identity
```

### 2. Bootstrap State Backend (First Time Only)

Before running Terraform, you must create the S3 bucket and DynamoDB table for state management. See [State Backend Bootstrap](#state-backend-bootstrap) section.

### 3. Create terraform.tfvars

```bash
cd infrastructure/terraform

# Copy the example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
vim terraform.tfvars
```

**Required variables to configure:**

```hcl
# Project identification
project_name = "langgraph-search-agent"
environment  = "production"
aws_region   = "us-east-1"

# GitHub OIDC (required for CI/CD)
github_org  = "your-github-org"
github_repo = "your-repo-name"
```

### 4. Initialize Terraform

```bash
# Initialize providers and modules
terraform init

# If using remote state backend
terraform init -backend-config="bucket=langgraph-search-agent-terraform-state" \
               -backend-config="key=state/terraform.tfstate" \
               -backend-config="region=us-east-1"
```

### 5. Plan Infrastructure Changes

```bash
# Preview changes
terraform plan -out=tfplan

# Review the plan output carefully
```

### 6. Apply Infrastructure

```bash
# Apply the planned changes
terraform apply tfplan

# Or apply directly (will prompt for confirmation)
terraform apply
```

### 7. Retrieve Output Values

```bash
# Display all outputs
terraform output

# Get specific output (for CI/CD configuration)
terraform output -raw cloudfront_distribution_id
terraform output -raw github_actions_role_arn
```

## State Backend Bootstrap

The Terraform state backend uses S3 for storage and DynamoDB for locking. These resources must exist before running `terraform init` with remote state.

### Option 1: Manual Bootstrap (Recommended for Production)

```bash
# Create S3 bucket for state storage
aws s3 mb s3://langgraph-search-agent-terraform-state --region us-east-1

# Enable versioning for state recovery
aws s3api put-bucket-versioning \
  --bucket langgraph-search-agent-terraform-state \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket langgraph-search-agent-terraform-state \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      },
      "BucketKeyEnabled": true
    }]
  }'

# Block public access
aws s3api put-public-access-block \
  --bucket langgraph-search-agent-terraform-state \
  --public-access-block-configuration '{
    "BlockPublicAcls": true,
    "IgnorePublicAcls": true,
    "BlockPublicPolicy": true,
    "RestrictPublicBuckets": true
  }'

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name langgraph-search-agent-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1

# Wait for table to be active
aws dynamodb wait table-exists --table-name langgraph-search-agent-terraform-locks
```

### Option 2: Local State First (Development)

For development, you can start with local state and migrate later:

```bash
# Comment out backend configuration in backend.tf temporarily
# Run terraform init with local state
terraform init

# Apply infrastructure
terraform apply

# Later, migrate to remote state
terraform init -migrate-state
```

### State Isolation by Environment

Each environment uses a separate state key:

| Environment | State Key |
|-------------|-----------|
| Development | `state/dev/terraform.tfstate` |
| Staging | `state/staging/terraform.tfstate` |
| Production | `state/prod/terraform.tfstate` |

## Module Documentation

### Module Dependency Graph

```
┌─────────────────────────────────────────────────────────────────┐
│                      Independent Modules                         │
├──────────────┬──────────────┬──────────────┬───────────────────┤
│     ECR      │   Database   │   Secrets    │     Storage       │
│  (registry)  │  (dynamodb)  │ (api keys)   │ (state bucket)    │
└──────┬───────┴──────────────┴──────┬───────┴───────────────────┘
       │                              │
       ▼                              ▼
┌──────────────┐              ┌──────────────┐
│  Networking  │              │  Monitoring  │
│ (vpc/subnets)│              │ (cloudwatch) │
└──────┬───────┘              └──────┬───────┘
       │                              │
       ▼                              ▼
┌──────────────┐              ┌──────────────┐
│     IAM      │◄─────────────│  ECS-Fargate │
│   (roles)    │              │  (cluster)   │
└──────┬───────┘              └──────────────┘
       │
       ▼
┌──────────────┐
│   Frontend   │
│ (s3/cf dist) │
└──────────────┘
```

### Module Descriptions

#### ECR Module (`modules/ecr/`)

Creates an Amazon Elastic Container Registry repository for storing Docker images.

**Resources:**
- `aws_ecr_repository` - Container image repository
- `aws_ecr_lifecycle_policy` - Retains last 10 tagged images

**Key Outputs:**
- `repository_url` - Full URL for docker push/pull
- `repository_arn` - ARN for IAM policies

---

#### Networking Module (`modules/networking/`)

Provisions the complete VPC infrastructure including subnets, gateways, and security groups.

**Resources:**
- `aws_vpc` - Primary VPC (10.0.0.0/16)
- `aws_subnet` - 2 public + 2 private subnets across 2 AZs
- `aws_internet_gateway` - Internet access for public subnets
- `aws_nat_gateway` - Outbound internet for private subnets
- `aws_route_table` - Routing configuration
- `aws_security_group` - ALB and ECS security groups

**Key Outputs:**
- `vpc_id` - VPC identifier
- `public_subnet_ids` - Public subnet IDs for ALB
- `private_subnet_ids` - Private subnet IDs for ECS tasks
- `alb_security_group_id` - Security group for load balancer
- `ecs_security_group_id` - Security group for containers

---

#### ECS-Fargate Module (`modules/ecs-fargate/`)

Deploys the ECS cluster, service, task definition, and Application Load Balancer.

**Resources:**
- `aws_ecs_cluster` - Fargate cluster
- `aws_ecs_cluster_capacity_providers` - Fargate capacity provider
- `aws_ecs_task_definition` - Container configuration (port 8000)
- `aws_ecs_service` - Service with load balancer attachment
- `aws_lb` - Application Load Balancer
- `aws_lb_target_group` - Health check on `/health`
- `aws_lb_listener` - HTTP listener (port 80)
- `aws_appautoscaling_target` - Auto-scaling target
- `aws_appautoscaling_policy` - CPU-based scaling (70% target)

**Key Outputs:**
- `cluster_arn` - ECS cluster ARN
- `cluster_name` - ECS cluster name
- `service_arn` - ECS service ARN
- `service_name` - ECS service name
- `task_definition_arn` - Task definition ARN
- `alb_dns_name` - Load balancer DNS name

---

#### Frontend Module (`modules/frontend/`)

Creates the S3 bucket for static hosting and CloudFront distribution for CDN.

**Resources:**
- `aws_s3_bucket` - Static asset storage
- `aws_s3_bucket_website_configuration` - Static hosting settings
- `aws_s3_bucket_policy` - CloudFront OAI access
- `aws_cloudfront_origin_access_identity` - Secure S3 access
- `aws_cloudfront_distribution` - CDN distribution

**Key Outputs:**
- `bucket_name` - S3 bucket name for deployment
- `bucket_arn` - Bucket ARN for policies
- `distribution_id` - CloudFront distribution ID for cache invalidation
- `distribution_domain` - CloudFront domain name

---

#### Storage Module (`modules/storage/`)

Creates S3 buckets for Terraform state and application logs.

**Resources:**
- `aws_s3_bucket` - State and log buckets
- `aws_s3_bucket_versioning` - State versioning
- `aws_s3_bucket_server_side_encryption_configuration` - Encryption
- `aws_dynamodb_table` - Terraform state locking

**Key Outputs:**
- `state_bucket_name` - Terraform state bucket
- `state_bucket_arn` - State bucket ARN
- `lock_table_name` - DynamoDB lock table name

---

#### Database Module (`modules/database/`)

Provisions the DynamoDB table for future session persistence.

**Resources:**
- `aws_dynamodb_table` - `langgraph-conversations` table
- TTL configuration for automatic session expiry

**Key Outputs:**
- `table_name` - DynamoDB table name
- `table_arn` - Table ARN for IAM policies

---

#### Monitoring Module (`modules/monitoring/`)

Creates CloudWatch log groups for container logging.

**Resources:**
- `aws_cloudwatch_log_group` - ECS container logs (`/ecs/langgraph-search-agent`)
- `aws_cloudwatch_metric_alarm` - CPU/Memory alerts (optional)

**Key Outputs:**
- `log_group_name` - Log group name for task definition
- `log_group_arn` - Log group ARN

---

#### IAM Module (`modules/iam/`)

Creates IAM roles for ECS execution and GitHub Actions OIDC authentication.

**Resources:**
- `aws_iam_openid_connect_provider` - GitHub Actions OIDC provider
- `aws_iam_role` - ECS task execution role, ECS task role, GitHub Actions role
- `aws_iam_role_policy_attachment` - Managed policy attachments
- `aws_iam_role_policy` - Inline policies for specific permissions

**Key Outputs:**
- `task_execution_role_arn` - ECS task execution role ARN
- `task_role_arn` - ECS task role ARN
- `github_actions_role_arn` - GitHub Actions OIDC role ARN

---

#### Secrets Module (`modules/secrets/`)

Creates Secrets Manager secrets for API keys.

**Resources:**
- `aws_secretsmanager_secret` - Secret containers (OPENAI_API_KEY, TAVILY_API_KEY)
- `aws_secretsmanager_secret_version` - Initial placeholder values

**Key Outputs:**
- `secret_arns` - Map of secret ARNs for ECS task definition

## Environment Deployment

### Deploying to Development

```bash
cd infrastructure/terraform/environments/dev

# Initialize with dev state key
terraform init -backend-config="key=state/dev/terraform.tfstate"

# Review and apply
terraform plan
terraform apply
```

### Deploying to Staging

```bash
cd infrastructure/terraform/environments/staging

# Initialize with staging state key
terraform init -backend-config="key=state/staging/terraform.tfstate"

# Review and apply
terraform plan
terraform apply
```

### Deploying to Production

```bash
cd infrastructure/terraform/environments/prod

# Initialize with production state key
terraform init -backend-config="key=state/prod/terraform.tfstate"

# Review plan carefully before applying
terraform plan -out=tfplan
terraform apply tfplan
```

### Environment Configuration Differences

| Setting | Development | Staging | Production |
|---------|-------------|---------|------------|
| ECS CPU | 256 | 512 | 1024 |
| ECS Memory | 512 MB | 1024 MB | 2048 MB |
| Minimum Tasks | 1 | 1 | 2 |
| Maximum Tasks | 2 | 3 | 10 |
| Desired Tasks | 1 | 1 | 2 |
| NAT Gateway | Single AZ | Single AZ | Multi-AZ |
| Auto-scaling Scale-in Cooldown | 60s | 120s | 300s |

## CI/CD Integration

### GitHub Actions Workflow

The `terraform.yml` workflow automates Terraform operations:

| Trigger | Action |
|---------|--------|
| Pull Request | `terraform plan` (output as PR comment) |
| Merge to main | `terraform apply` (auto-approve) |

### OIDC Authentication Setup

After applying Terraform, configure GitHub repository secrets:

1. **Get the OIDC role ARN:**
   ```bash
   terraform output -raw github_actions_role_arn
   ```

2. **Add to GitHub Secrets:**
   - Go to Repository → Settings → Secrets and variables → Actions
   - Add secret `AWS_ROLE_ARN` with the role ARN value

3. **Remove legacy credentials:**
   - Delete `AWS_ACCESS_KEY_ID` secret
   - Delete `AWS_SECRET_ACCESS_KEY` secret

### Workflow Integration

The existing CI/CD workflows consume Terraform outputs:

**backend-deploy.yml:**
- Uses `AWS_ROLE_ARN` for OIDC authentication
- Deploys to ECS cluster `langgraph-search-agent-cluster`
- Updates ECS service `langgraph-search-agent-service`
- Pushes images to ECR repository `langgraph-search-agent-backend`

**frontend-deploy.yml:**
- Uses `AWS_ROLE_ARN` for OIDC authentication
- Syncs to S3 bucket `langgraph-search-agent-frontend-production`
- Invalidates CloudFront distribution (ID from Terraform output)

### Deployment Sequence

```
1. Terraform Apply (Infrastructure)
         │
         ├──► ECR Repository Created
         │
         ├──► ECS Cluster/Service Ready
         │
         ├──► S3 Bucket Created
         │
         └──► CloudFront Distribution Active
         │
         ▼
2. Backend Deploy (on code changes)
         │
         ├──► Build Docker Image
         │
         ├──► Push to ECR
         │
         └──► Update ECS Service
         │
         ▼
3. Frontend Deploy (on code changes)
         │
         ├──► Build React App
         │
         ├──► Sync to S3
         │
         └──► Invalidate CloudFront Cache
```

## Resource Naming Convention

All resources follow the pattern: `{project}-{component}` or `{project}-{component}-{environment}`

### Standard Resource Names

| Resource Type | Name Pattern | Example |
|---------------|--------------|---------|
| ECR Repository | `{project}-backend` | `langgraph-search-agent-backend` |
| ECS Cluster | `{project}-cluster` | `langgraph-search-agent-cluster` |
| ECS Service | `{project}-service` | `langgraph-search-agent-service` |
| ECS Task Definition | `{project}-task` | `langgraph-search-agent-task` |
| Container Name | `{project}-container` | `langgraph-search-agent-container` |
| VPC | `{project}-vpc` | `langgraph-search-agent-vpc` |
| ALB | `{project}-alb` | `langgraph-search-agent-alb` |
| S3 Frontend | `{project}-frontend-{env}` | `langgraph-search-agent-frontend-production` |
| S3 State | `{project}-terraform-state` | `langgraph-search-agent-terraform-state` |
| DynamoDB Lock | `{project}-terraform-locks` | `langgraph-search-agent-terraform-locks` |
| DynamoDB App | `langgraph-conversations` | `langgraph-conversations` |
| CloudWatch Logs | `/ecs/{project}` | `/ecs/langgraph-search-agent` |

## Resource Tagging

All AWS resources are tagged with the following standard tags:

```hcl
{
  Project     = "langgraph-search-agent"
  Environment = "production"  # or "dev", "staging"
  ManagedBy   = "terraform"
  Region      = "us-east-1"
}
```

### Tag Usage

| Tag | Purpose |
|-----|---------|
| `Project` | Identifies all resources belonging to this application |
| `Environment` | Distinguishes between dev, staging, and production |
| `ManagedBy` | Indicates infrastructure-as-code management |
| `Region` | Documents the deployment region |

### Cost Allocation

Tags enable AWS Cost Explorer to track spending by:
- Project (all LangGraph Search Agent costs)
- Environment (dev vs staging vs production costs)

## Security Considerations

### State File Security

- **Encryption:** S3 bucket uses AES-256 server-side encryption
- **Access Control:** Bucket policy restricts access to authorized IAM principals
- **Versioning:** Enabled for state recovery in case of corruption
- **Public Access:** All public access is blocked

### Secrets Management

- **Never commit secrets:** API keys are stored in AWS Secrets Manager, not in code
- **Placeholder values:** Terraform creates secret containers with placeholder values
- **Manual update required:** Update secret values via AWS Console or CLI after apply
- **ECS integration:** Task definition references secrets by ARN

```bash
# Update secret value after initial deployment
aws secretsmanager put-secret-value \
  --secret-id langgraph-search-agent/openai-api-key \
  --secret-string "your-actual-api-key"
```

### IAM Least Privilege

| Role | Purpose | Permissions |
|------|---------|-------------|
| ECS Task Execution | Task startup | ECR pull, CloudWatch logs, Secrets Manager read |
| ECS Task | Container runtime | DynamoDB access (future), minimal AWS SDK calls |
| GitHub Actions | CI/CD pipelines | ECR push, ECS deploy, S3 sync, CloudFront invalidate |

### OIDC Authentication Benefits

- **No long-lived credentials:** Eliminates risk of credential exposure
- **Short-lived tokens:** Tokens expire after workflow completion
- **Repository-scoped:** Trust policy limits access to specific repository
- **Branch conditions:** Can restrict to specific branches (e.g., main only)

### Network Security

| Security Group | Inbound | Outbound |
|----------------|---------|----------|
| ALB | 80, 443 from 0.0.0.0/0 | All to ECS SG |
| ECS | 8000 from ALB SG only | 443 to 0.0.0.0/0 (APIs) |

## Outputs Reference

### Primary Outputs for CI/CD

| Output | Description | Used By |
|--------|-------------|---------|
| `ecr_repository_url` | ECR repository URL | backend-deploy.yml |
| `ecs_cluster_name` | ECS cluster name | backend-deploy.yml |
| `ecs_service_name` | ECS service name | backend-deploy.yml |
| `frontend_bucket_name` | S3 bucket name | frontend-deploy.yml |
| `cloudfront_distribution_id` | CloudFront ID | frontend-deploy.yml |
| `github_actions_role_arn` | OIDC role ARN | All workflows |
| `alb_dns_name` | Application URL | Documentation |

### Retrieving Outputs

```bash
# All outputs
terraform output

# JSON format (for scripting)
terraform output -json

# Specific output (raw value)
terraform output -raw github_actions_role_arn

# Sensitive output
terraform output -raw secrets_arns
```

## Troubleshooting

### Common Issues

#### State Lock Error

```
Error: Error acquiring the state lock
```

**Solution:** Check for stuck locks and force unlock if necessary:
```bash
terraform force-unlock LOCK_ID
```

#### Backend Initialization Error

```
Error: Failed to get existing workspaces
```

**Solution:** Ensure S3 bucket and DynamoDB table exist (see [State Backend Bootstrap](#state-backend-bootstrap)).

#### OIDC Authentication Failure

```
Error: Could not assume role
```

**Solution:** Verify:
1. OIDC provider exists in AWS IAM
2. Role trust policy includes correct GitHub repository
3. `AWS_ROLE_ARN` secret is correctly configured

#### Resource Already Exists

```
Error: Resource already exists
```

**Solution:** Import existing resource into Terraform state:
```bash
terraform import aws_ecr_repository.main langgraph-search-agent-backend
```

### Validation Commands

```bash
# Format check
terraform fmt -check -recursive

# Validate configuration
terraform validate

# Check for drift
terraform plan -refresh-only
```

### Rollback Procedures

**Revert to Previous State:**
```bash
# List state versions
aws s3api list-object-versions --bucket langgraph-search-agent-terraform-state --prefix state/

# Download previous version
aws s3api get-object --bucket langgraph-search-agent-terraform-state \
  --key state/terraform.tfstate --version-id VERSION_ID \
  terraform.tfstate.backup

# Restore (use with caution)
terraform state push terraform.tfstate.backup
```

**Destroy and Recreate:**
```bash
# Destroy specific module
terraform destroy -target=module.ecs_fargate

# Recreate
terraform apply -target=module.ecs_fargate
```

---

## Support

For issues with this Terraform configuration:

1. Check this README and troubleshooting section
2. Review Terraform plan output for detailed error messages
3. Verify AWS credentials and permissions
4. Check AWS CloudWatch logs for runtime issues

## License

This infrastructure configuration is part of the LangGraph Search Agent project.
