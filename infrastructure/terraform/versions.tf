# -----------------------------------------------------------------------------
# Terraform Version Constraints
# -----------------------------------------------------------------------------
# This file defines version requirements for Terraform and its providers to
# ensure consistent behavior across all team members and CI/CD environments.
#
# Version Selection Rationale:
# - Terraform >= 1.5.0: Minimum stable version supporting import blocks,
#   check blocks, and modern HCL features. Required for production stability.
# - AWS Provider ~> 5.0: Latest stable major version with full ECS Fargate
#   support, improved S3 configuration APIs, and enhanced security features.
# - Random Provider ~> 3.5: Stable API for unique suffix generation used in
#   bucket names and resource names to ensure global uniqueness.
#
# Provider Version Flexibility:
# - Pessimistic constraint (~>) allows patch updates for security fixes
# - Major version pinning prevents breaking changes during terraform init
#
# CI/CD Compatibility:
# - hashicorp/setup-terraform@v3 action in GitHub workflow respects these
#   constraints and installs the appropriate version
# - .terraform-version file in this directory aligns with required_version
#   for tfenv-based local development environments
# -----------------------------------------------------------------------------

terraform {
  # Minimum Terraform version requirement
  # 1.5.0+ provides:
  # - import blocks for importing existing resources
  # - check blocks for custom validation conditions
  # - Modern HCL syntax and improved plan output
  # - Enhanced provider installation and caching
  required_version = ">= 1.5.0"

  required_providers {
    # AWS Provider - Primary cloud provider for all infrastructure resources
    # Version 5.x includes:
    # - Full ECS Fargate support with capacity providers
    # - Improved S3 bucket configuration (separate resources)
    # - Enhanced CloudFront distribution options
    # - Native support for OIDC authentication
    # - Better IAM policy management
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    # Random Provider - Used for generating unique suffixes
    # Ensures globally unique names for:
    # - S3 bucket names (must be globally unique)
    # - Resource identifiers requiring uniqueness
    # - Preventing naming collisions across environments
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}
