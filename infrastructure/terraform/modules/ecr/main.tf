# -----------------------------------------------------------------------------
# ECR Module - Main Configuration
# -----------------------------------------------------------------------------
# Creates an Elastic Container Registry (ECR) repository for storing Docker
# images of the LangGraph Search Agent backend application.
#
# Features:
# - Image scanning on push for vulnerability detection
# - Lifecycle policy to retain only the last N tagged images
# - AES256 encryption for images at rest
# - Optional repository policy for cross-account access
# -----------------------------------------------------------------------------

locals {
  default_tags = {
    Name   = var.repository_name
    Module = "ecr"
  }
  merged_tags = merge(local.default_tags, var.tags)
}

# -----------------------------------------------------------------------------
# ECR Repository
# -----------------------------------------------------------------------------
# Primary container image repository for the backend application.
# Images are pushed here by the CI/CD pipeline (backend-deploy.yml).
# -----------------------------------------------------------------------------
resource "aws_ecr_repository" "main" {
  name                 = var.repository_name
  image_tag_mutability = var.image_tag_mutability
  force_delete         = var.force_delete

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = local.merged_tags
}

# -----------------------------------------------------------------------------
# ECR Lifecycle Policy
# -----------------------------------------------------------------------------
# Automatically removes old images to control storage costs and maintain
# repository hygiene. Retains the last N tagged images and removes
# untagged images after 1 day.
# -----------------------------------------------------------------------------
resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only the last ${var.image_retention_count} tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "latest"]
          countType     = "imageCountMoreThan"
          countNumber   = var.image_retention_count
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Remove untagged images after 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# ECR Repository Policy (Optional)
# -----------------------------------------------------------------------------
# Applied only when cross-account access is required.
# Use var.repository_policy to specify custom access policies.
# -----------------------------------------------------------------------------
resource "aws_ecr_repository_policy" "main" {
  count = var.repository_policy != null ? 1 : 0

  repository = aws_ecr_repository.main.name
  policy     = var.repository_policy
}
