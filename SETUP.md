# Setup Instructions

## Prerequisites

Before getting started, ensure you have the following installed and configured:

### Required for Local Development

- **Python 3.12+**: Required for the backend application
- **Node.js 18+**: Required for the frontend application
- **Docker & Docker Compose**: Required for containerized development (Option A)

### Required for AWS Deployment (Optional)

- **Terraform CLI** (>= 1.5.0): Infrastructure as Code tool for AWS provisioning
  - Install: https://developer.hashicorp.com/terraform/downloads
  - Verify: `terraform --version`

- **AWS CLI** (>= 2.0): Command-line interface for AWS services
  - Install: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
  - Verify: `aws --version`

- **AWS Account**: Active AWS account with the following IAM permissions:
  - Full access to: ECR, ECS, EC2 (VPC), ELB, S3, CloudFront, DynamoDB, IAM, Secrets Manager, CloudWatch
  - Ability to create IAM roles and OIDC providers
  - Configure credentials: `aws configure` or use environment variables

> **Note**: For detailed Terraform documentation, see [`infrastructure/terraform/README.md`](infrastructure/terraform/README.md)

---

## Step 1: Get API Keys

1. **OpenAI API Key**: Get from https://platform.openai.com/api-keys
2. **Tavily API Key**: Get from https://tavily.com/

## Step 2: Configure Backend

```bash
cd backend
cp .env.example .env
```

Edit `backend/.env` and add your API keys:
```
OPENAI_API_KEY=sk-your-key-here
TAVILY_API_KEY=tvly-your-key-here
```

## Step 3: Run Locally

### Option A: Docker Compose (Easiest)
```bash
docker-compose up
```

### Option B: Manual Setup

**Terminal 1 - Backend:**
```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

**Terminal 2 - Frontend:**
```bash
cd frontend
npm install
npm run dev
```

## Step 4: Test

Open your browser to http://localhost:3000 and start chatting!

## Step 5: Deploy to AWS (Optional)

This project includes complete Terraform infrastructure-as-code for automated AWS provisioning. Follow these steps to deploy the application to AWS.

> **Prerequisite**: Ensure you have completed the [AWS Deployment Prerequisites](#required-for-aws-deployment-optional) section above.

### Step 5a: Bootstrap Terraform State Backend

Before using Terraform, you need to create the S3 bucket and DynamoDB table for remote state management:

```bash
# Create S3 bucket for Terraform state
aws s3api create-bucket \
  --bucket langgraph-search-agent-terraform-state \
  --region us-east-1

# Enable versioning on the state bucket
aws s3api put-bucket-versioning \
  --bucket langgraph-search-agent-terraform-state \
  --versioning-configuration Status=Enabled

# Enable server-side encryption
aws s3api put-bucket-encryption \
  --bucket langgraph-search-agent-terraform-state \
  --server-side-encryption-configuration '{
    "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
  }'

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name langgraph-search-agent-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### Step 5b: Initialize Terraform

Navigate to the Terraform directory and initialize:

```bash
cd infrastructure/terraform

# Copy the example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your settings
# (At minimum, update github_repository_owner and github_repository_name)

# Initialize Terraform with the backend configuration
terraform init
```

### Step 5c: Plan Infrastructure

Review the planned infrastructure changes before applying:

```bash
# Generate and review the execution plan
terraform plan -out=tfplan

# This will show all resources to be created:
# - VPC with public/private subnets
# - ECR repository for container images
# - ECS Fargate cluster and service
# - Application Load Balancer
# - S3 bucket for frontend static assets
# - CloudFront CDN distribution
# - IAM roles for ECS and GitHub Actions OIDC
# - CloudWatch log groups
# - Secrets Manager secrets (placeholders)
# - DynamoDB table (for future use)
```

### Step 5d: Apply Infrastructure

Deploy the infrastructure to AWS:

```bash
# Apply the planned changes
terraform apply tfplan

# Or apply directly (will prompt for confirmation)
terraform apply
```

After successful deployment, Terraform will output important values:
- `ecr_repository_url`: ECR repository URL for container images
- `ecs_cluster_arn`: ECS cluster ARN
- `alb_dns_name`: Application Load Balancer DNS name (backend URL)
- `cloudfront_distribution_id`: CloudFront distribution ID
- `cloudfront_domain_name`: CloudFront domain (frontend URL)
- `github_actions_role_arn`: IAM role ARN for GitHub Actions OIDC

### Step 5e: Configure GitHub Secrets for OIDC

After Terraform deployment, configure your GitHub repository secrets for CI/CD:

1. **Get the IAM role ARN from Terraform outputs:**
   ```bash
   terraform output github_actions_role_arn
   ```

2. **Add the following secrets to your GitHub repository** (Settings → Secrets and variables → Actions):

   | Secret Name | Value | Description |
   |-------------|-------|-------------|
   | `AWS_ROLE_ARN` | From Terraform output | IAM role for OIDC authentication |
   | `OPENAI_API_KEY` | Your OpenAI API key | For LLM integration |
   | `TAVILY_API_KEY` | Your Tavily API key | For web search |

3. **Update API Keys in Secrets Manager** (optional, for ECS tasks):
   ```bash
   # Update OpenAI API key
   aws secretsmanager put-secret-value \
     --secret-id langgraph-search-agent/openai-api-key \
     --secret-string '{"api_key":"sk-your-actual-key"}'

   # Update Tavily API key
   aws secretsmanager put-secret-value \
     --secret-id langgraph-search-agent/tavily-api-key \
     --secret-string '{"api_key":"tvly-your-actual-key"}'
   ```

### Environment-Specific Deployments

The Terraform configuration supports multiple environments (dev, staging, prod):

```bash
# Deploy to development environment
cd infrastructure/terraform/environments/dev
terraform init
terraform apply

# Deploy to staging environment
cd infrastructure/terraform/environments/staging
terraform init
terraform apply

# Deploy to production environment
cd infrastructure/terraform/environments/prod
terraform init
terraform apply
```

Each environment has its own:
- State file (isolated in S3)
- Variable values (`terraform.tfvars`)
- Resource sizing (CPU, memory, scaling)

### Verify Deployment

After successful deployment:

1. **Check ECS service health:**
   ```bash
   aws ecs describe-services \
     --cluster langgraph-search-agent-cluster \
     --services langgraph-search-agent-service \
     --query 'services[0].{status:status,running:runningCount,desired:desiredCount}'
   ```

2. **Access the application:**
   - Backend API: Use the ALB DNS name from Terraform outputs
   - Frontend: Use the CloudFront domain from Terraform outputs

3. **Trigger CI/CD deployment:**
   - Push to `main` branch to trigger automatic deployment
   - Backend: `.github/workflows/backend-deploy.yml`
   - Frontend: `.github/workflows/frontend-deploy.yml`

### Teardown Infrastructure

To destroy all AWS resources (use with caution):

```bash
cd infrastructure/terraform
terraform destroy
```

> **Warning**: This will permanently delete all resources including data in S3 and DynamoDB.

---

For comprehensive Terraform documentation including module details, variable references, and troubleshooting, see [`infrastructure/terraform/README.md`](infrastructure/terraform/README.md).
