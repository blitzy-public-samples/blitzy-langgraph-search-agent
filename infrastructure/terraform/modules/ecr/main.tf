# -----------------------------------------------------------------------------
# ECR Module - Main Configuration
# -----------------------------------------------------------------------------
# Creates an Elastic Container Registry (ECR) repository for storing Docker
# images of the LangGraph Search Agent backend application.
#
# This module is designed to work with the CI/CD pipeline defined in
# .github/workflows/backend-deploy.yml which pushes images tagged with:
# - Git commit SHA (e.g., abc123def456...)
# - "latest" tag
# - Semantic version tags (e.g., v1.0.0)
#
# Features:
# - Image scanning on push for vulnerability detection
# - Lifecycle policy to retain only the last N tagged images
# - AES256 encryption for images at rest
# - Optional repository policy for cross-account access
#
# Resource Naming Convention:
# - Repository: langgraph-search-agent-backend (matches CI/CD workflow)
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Local Values
# -----------------------------------------------------------------------------
# Define default tags and merge them with user-provided tags for consistent
# resource tagging across all ECR resources.
# -----------------------------------------------------------------------------
locals {
  # Default tags applied to all resources in this module
  default_tags = {
    Name   = var.repository_name
    Module = "ecr"
  }

  # Merge default tags with user-provided tags
  # User tags take precedence over default tags in case of conflicts
  merged_tags = merge(local.default_tags, var.tags)

  # Lifecycle policy JSON for image retention
  # Handles multiple tagging patterns used by the CI/CD pipeline
  lifecycle_policy = jsonencode({
    rules = [
      # Rule 1: Retain the last N images tagged with "latest"
      # The CI/CD pipeline always updates the "latest" tag
      {
        rulePriority = 1
        description  = "Keep the last ${var.image_retention_count} images tagged with 'latest'"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["latest"]
          countType     = "imageCountMoreThan"
          countNumber   = var.image_retention_count
        }
        action = {
          type = "expire"
        }
      },
      # Rule 2: Retain the last N images with semantic version tags (v*)
      # Supports version tags like v1.0.0, v2.1.3, etc.
      {
        rulePriority = 2
        description  = "Keep the last ${var.image_retention_count} images with version tags"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = var.image_retention_count
        }
        action = {
          type = "expire"
        }
      },
      # Rule 3: Retain the last N images with SHA/commit tags
      # CI/CD pipeline tags images with commit SHA (hex characters 0-9, a-f)
      # We match common SHA prefixes to capture most commit-tagged images
      {
        rulePriority = 3
        description  = "Keep the last ${var.image_retention_count} images with commit SHA tags"
        selection = {
          tagStatus = "tagged"
          tagPrefixList = [
            "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
            "a", "b", "c", "d", "e", "f"
          ]
          countType   = "imageCountMoreThan"
          countNumber = var.image_retention_count
        }
        action = {
          type = "expire"
        }
      },
      # Rule 4: Remove untagged images after retention period
      # Untagged images are created when tags are moved to newer images
      # Clean these up to reduce storage costs
      {
        rulePriority = 10
        description  = "Remove untagged images after ${var.untagged_image_retention_days} day(s)"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.untagged_image_retention_days
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# ECR Repository
# -----------------------------------------------------------------------------
# Primary container image repository for the backend application.
# Images are pushed here by the CI/CD pipeline (backend-deploy.yml).
#
# Configuration details:
# - name: Must match ECR_REPOSITORY env var in backend-deploy.yml
# - image_tag_mutability: MUTABLE to allow overwriting "latest" tag
# - scan_on_push: Enables automatic vulnerability scanning
# - encryption_type: AES256 provides AWS-managed encryption at rest
# - force_delete: Prevents accidental deletion of repository with images
# -----------------------------------------------------------------------------
resource "aws_ecr_repository" "main" {
  name                 = var.repository_name
  image_tag_mutability = var.image_tag_mutability
  force_delete         = var.force_delete

  # Enable image scanning on push for security vulnerability detection
  # Scans are performed automatically when images are pushed
  # Results are available in the ECR console and via API
  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  # Configure encryption for images at rest
  # AES256 uses AWS-managed keys (no additional KMS costs)
  # For customer-managed keys, use encryption_type = "KMS" with kms_key ARN
  encryption_configuration {
    encryption_type = var.encryption_type
    # kms_key is only used when encryption_type = "KMS"
    # kms_key = var.kms_key_arn
  }

  tags = local.merged_tags

  lifecycle {
    # Prevent destruction of repository containing production images
    # Remove this block or set to false if you need to destroy the repository
    prevent_destroy = false
  }
}

# -----------------------------------------------------------------------------
# ECR Lifecycle Policy
# -----------------------------------------------------------------------------
# Automatically removes old images to control storage costs and maintain
# repository hygiene. The policy implements a multi-rule approach:
#
# 1. Retains the last N images tagged with "latest"
# 2. Retains the last N images with semantic version tags (v*)
# 3. Retains the last N images with commit SHA tags (hex prefixes)
# 4. Removes untagged images after the configured retention period
#
# Note: ECR lifecycle policies use prefix matching for tags. Since commit
# SHA hashes are hexadecimal (0-9, a-f), we use those characters as prefixes
# to match SHA-tagged images.
# -----------------------------------------------------------------------------
resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name
  policy     = local.lifecycle_policy

  depends_on = [aws_ecr_repository.main]
}

# -----------------------------------------------------------------------------
# ECR Repository Policy (Optional)
# -----------------------------------------------------------------------------
# Applied only when cross-account access is required or custom access
# policies need to be configured.
#
# Use cases:
# - Cross-account image pulls (e.g., from staging to production accounts)
# - Service-specific access controls
# - AWS Organizations-based access policies
#
# Example policy for cross-account access:
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Sid": "CrossAccountPull",
#       "Effect": "Allow",
#       "Principal": {
#         "AWS": "arn:aws:iam::ACCOUNT_ID:root"
#       },
#       "Action": [
#         "ecr:GetDownloadUrlForLayer",
#         "ecr:BatchGetImage",
#         "ecr:BatchCheckLayerAvailability"
#       ]
#     }
#   ]
# }
# -----------------------------------------------------------------------------
resource "aws_ecr_repository_policy" "main" {
  count = var.repository_policy != null ? 1 : 0

  repository = aws_ecr_repository.main.name
  policy     = var.repository_policy

  depends_on = [aws_ecr_repository.main]
}
