# =============================================================================
# Terraform Remote State Backend Configuration
# =============================================================================
#
# This file configures Terraform to use a remote state backend with S3 for 
# state storage and DynamoDB for state locking. This enables:
#
#   1. Team Collaboration: Multiple team members can work on infrastructure
#      without conflicting state modifications
#   2. State Locking: DynamoDB prevents concurrent operations that could
#      corrupt the state file
#   3. State Versioning: S3 bucket versioning (enabled via storage module)
#      allows state recovery from accidental deletions or corruptions
#   4. Encryption: Server-side encryption protects sensitive data in state files
#   5. Environment Isolation: State key patterns support multi-environment deployments
#
# =============================================================================
# BOOTSTRAP REQUIREMENTS
# =============================================================================
#
# The S3 bucket and DynamoDB table must exist BEFORE running `terraform init`.
# You have two options:
#
# Option 1: Use local state initially, then migrate after the storage module
#           creates the backend resources
#           - Comment out the backend block below
#           - Run terraform apply to create resources
#           - Uncomment the backend block
#           - Run terraform init -migrate-state
#
# Option 2: Manually create the backend resources via AWS CLI before first run
#           (See bootstrap commands below)
#
# =============================================================================
# BOOTSTRAP COMMANDS (AWS CLI)
# =============================================================================
#
# Create the S3 bucket:
# aws s3 mb s3://langgraph-search-agent-terraform-state --region us-east-1
#
# Enable versioning on the S3 bucket:
# aws s3api put-bucket-versioning \
#   --bucket langgraph-search-agent-terraform-state \
#   --versioning-configuration Status=Enabled
#
# Enable server-side encryption on the S3 bucket:
# aws s3api put-bucket-encryption \
#   --bucket langgraph-search-agent-terraform-state \
#   --server-side-encryption-configuration '{
#     "Rules": [
#       {
#         "ApplyServerSideEncryptionByDefault": {
#           "SSEAlgorithm": "AES256"
#         },
#         "BucketKeyEnabled": true
#       }
#     ]
#   }'
#
# Block public access on the S3 bucket:
# aws s3api put-public-access-block \
#   --bucket langgraph-search-agent-terraform-state \
#   --public-access-block-configuration '{
#     "BlockPublicAcls": true,
#     "IgnorePublicAcls": true,
#     "BlockPublicPolicy": true,
#     "RestrictPublicBuckets": true
#   }'
#
# Create the DynamoDB table for state locking:
# aws dynamodb create-table \
#   --table-name langgraph-search-agent-terraform-locks \
#   --attribute-definitions AttributeName=LockID,AttributeType=S \
#   --key-schema AttributeName=LockID,KeyType=HASH \
#   --billing-mode PAY_PER_REQUEST \
#   --region us-east-1
#
# =============================================================================
# STATE KEY PATTERNS FOR ENVIRONMENT ISOLATION
# =============================================================================
#
# Each environment should use a unique state key to isolate state files:
#
#   Development:  state/dev/terraform.tfstate
#   Staging:      state/staging/terraform.tfstate
#   Production:   state/prod/terraform.tfstate
#
# When deploying to a specific environment, either:
#   1. Use the -backend-config flag:
#      terraform init -backend-config="key=state/dev/terraform.tfstate"
#
#   2. Use workspace-based isolation:
#      terraform workspace new dev
#      terraform workspace select dev
#
#   3. Use the environments/ directory with separate configurations
#
# =============================================================================

terraform {
  backend "s3" {
    # S3 bucket for state storage
    # This bucket must exist before running terraform init
    # Versioning should be enabled for state recovery capabilities
    bucket = "langgraph-search-agent-terraform-state"

    # State file path within the bucket
    # Override with -backend-config="key=state/{env}/terraform.tfstate" for
    # environment-specific state isolation
    key = "state/terraform.tfstate"

    # AWS region for the state bucket
    # All resources are deployed to us-east-1 per project requirements
    region = "us-east-1"

    # Enable server-side encryption for the state file
    # Protects sensitive data stored in Terraform state
    encrypt = true

    # DynamoDB table for state locking
    # Prevents concurrent operations that could corrupt the state
    # Table must have a primary key named 'LockID' (String type)
    dynamodb_table = "langgraph-search-agent-terraform-locks"

    # Skip metadata API check (useful for CI/CD environments)
    # Uncomment if using IAM roles attached to EC2 instances or ECS tasks
    # skip_metadata_api_check = true
  }
}
