# LangGraph Search Agent

A full-stack AI-powered search agent application using LangGraph, deployed on AWS with CI/CD.

## Features

- 🤖 LangGraph agent with web search capabilities
- 🔍 Real-time search using Tavily API
- 💬 Conversational interface with session memory
- 🚀 Automated CI/CD pipeline with GitHub Actions
- ☁️ AWS deployment (ECS Fargate + S3 + CloudFront)

## Prerequisites

- Python 3.11+
- Node.js 18+
- Docker
- Terraform >= 1.5.0
- AWS CLI >= 2.0
- AWS Account with appropriate IAM permissions
- OpenAI API Key
- Tavily API Key

## Quick Start

### 1. Set up environment variables

```bash
# Backend
cp backend/.env.example backend/.env
# Edit backend/.env with your API keys
```

### 2. Run with Docker Compose (Recommended)

```bash
docker-compose up
```

The backend will be available at http://localhost:8000
The frontend will be available at http://localhost:3000

### 3. Or run separately

**Backend:**
```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

**Frontend:**
```bash
cd frontend
npm install
npm run dev
```

## API Endpoints

- `GET /` - Root endpoint
- `GET /health` - Health check
- `POST /query` - Process search query

## Testing

```bash
# Test backend health
curl http://localhost:8000/health

# Test query endpoint
curl -X POST http://localhost:8000/query \
  -H "Content-Type: application/json" \
  -d '{"query": "What is LangGraph?"}'
```

## AWS Deployment

This project uses Terraform to provision and manage all AWS infrastructure. Quick start:

```bash
cd infrastructure/terraform

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Apply infrastructure
terraform apply
```

See [infrastructure/terraform/README.md](infrastructure/terraform/README.md) for detailed deployment instructions.

> **Note:** AWS authentication uses OIDC (OpenID Connect) for GitHub Actions, eliminating the need for long-lived AWS credentials. See the [CI/CD](#cicd) section for details.

## Infrastructure

The project infrastructure is fully automated using Terraform Infrastructure as Code (IaC). All AWS resources are provisioned and managed through the `infrastructure/terraform/` directory.

### AWS Resources Managed

| Resource | Purpose |
|----------|---------|
| **ECR** | Container image repository for backend Docker images |
| **ECS Fargate** | Serverless container orchestration for backend API |
| **Application Load Balancer** | Traffic distribution and health checks |
| **S3** | Static hosting for React frontend assets |
| **CloudFront** | CDN for frontend content delivery |
| **VPC** | Isolated network with public/private subnets |
| **IAM** | Roles and policies for ECS tasks and GitHub Actions |
| **Secrets Manager** | Secure storage for API keys (OpenAI, Tavily) |
| **DynamoDB** | NoSQL database for session persistence (future-ready) |
| **CloudWatch** | Container logging and monitoring |

### Multi-Environment Support

The infrastructure supports multiple environments with environment-specific configurations:

- **Development** (`environments/dev/`) - Minimal resources for development
- **Staging** (`environments/staging/`) - Pre-production testing
- **Production** (`environments/prod/`) - Full production deployment

### State Management

Terraform state is stored remotely using:
- **S3 Bucket** - Versioned state file storage
- **DynamoDB Table** - State locking for team collaboration

For complete infrastructure documentation, see [infrastructure/terraform/README.md](infrastructure/terraform/README.md).

## CI/CD

The project uses GitHub Actions for automated continuous integration and deployment.

### Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `terraform.yml` | PR to main, Push to main | Terraform plan on PR, apply on merge |
| `backend-deploy.yml` | Push to main | Build and deploy backend to ECS |
| `frontend-deploy.yml` | Push to main | Build and deploy frontend to S3/CloudFront |

### OIDC Authentication

All workflows use OpenID Connect (OIDC) for AWS authentication:

- **No long-lived credentials** - Eliminates AWS access keys in GitHub Secrets
- **Short-lived tokens** - Temporary credentials issued per workflow run
- **Repository-scoped** - Permissions limited to specific repository

### Deployment Flow

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   PR Created    │────▶│ Terraform Plan  │────▶│  Review & Merge │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                         │
                        ┌────────────────────────────────┘
                        ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│ Terraform Apply │────▶│  Backend Deploy │────▶│ Frontend Deploy │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

## Project Structure

```
langgraph-search-agent/
├── backend/                      # FastAPI backend
│   ├── app/                      # Application source code
│   ├── tests/                    # Backend tests
│   ├── Dockerfile                # Container definition
│   └── requirements.txt          # Python dependencies
├── frontend/                     # React frontend
│   ├── src/                      # Frontend source code
│   └── package.json              # Node.js dependencies
├── .github/workflows/            # CI/CD pipelines
│   ├── terraform.yml             # Infrastructure deployment
│   ├── backend-deploy.yml        # Backend deployment
│   └── frontend-deploy.yml       # Frontend deployment
├── infrastructure/               # Terraform IaC
│   └── terraform/
│       ├── main.tf               # Root module orchestration
│       ├── variables.tf          # Input variable declarations
│       ├── outputs.tf            # Output values for CI/CD
│       ├── backend.tf            # S3 + DynamoDB state backend
│       ├── versions.tf           # Provider version constraints
│       ├── locals.tf             # Common tags and computed values
│       ├── modules/              # Reusable Terraform modules
│       │   ├── ecr/              # Container registry
│       │   ├── ecs-fargate/      # ECS cluster, service, ALB
│       │   ├── frontend/         # S3 + CloudFront
│       │   ├── networking/       # VPC, subnets, security groups
│       │   ├── iam/              # IAM roles and OIDC
│       │   ├── secrets/          # Secrets Manager
│       │   ├── database/         # DynamoDB tables
│       │   ├── monitoring/       # CloudWatch resources
│       │   └── storage/          # S3 buckets for state
│       └── environments/         # Environment configurations
│           ├── dev/              # Development settings
│           ├── staging/          # Staging settings
│           └── prod/             # Production settings
└── docker-compose.yml            # Local development
```

## License

MIT
