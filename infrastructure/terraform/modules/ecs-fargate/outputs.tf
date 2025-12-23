# -----------------------------------------------------------------------------
# ECS Fargate Module - Outputs
# -----------------------------------------------------------------------------
# Exports ECS cluster, service, and ALB details for use by other modules
# and CI/CD pipelines.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# ECS Cluster Outputs
# -----------------------------------------------------------------------------
output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

# -----------------------------------------------------------------------------
# ECS Service Outputs
# -----------------------------------------------------------------------------
output "service_id" {
  description = "ID of the ECS service"
  value       = aws_ecs_service.main.id
}

output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.main.name
}

output "service_arn" {
  description = "ARN of the ECS service"
  value       = aws_ecs_service.main.id
}

# -----------------------------------------------------------------------------
# Task Definition Outputs
# -----------------------------------------------------------------------------
output "task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = aws_ecs_task_definition.main.arn
}

output "task_definition_family" {
  description = "Family of the ECS task definition"
  value       = aws_ecs_task_definition.main.family
}

output "task_definition_revision" {
  description = "Revision number of the ECS task definition"
  value       = aws_ecs_task_definition.main.revision
}

# -----------------------------------------------------------------------------
# Application Load Balancer Outputs
# -----------------------------------------------------------------------------
output "alb_id" {
  description = "ID of the Application Load Balancer"
  value       = aws_lb.main.id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer (for Route53)"
  value       = aws_lb.main.zone_id
}

# -----------------------------------------------------------------------------
# Target Group Outputs
# -----------------------------------------------------------------------------
output "target_group_arn" {
  description = "ARN of the ALB target group"
  value       = aws_lb_target_group.main.arn
}

output "target_group_name" {
  description = "Name of the ALB target group"
  value       = aws_lb_target_group.main.name
}

# -----------------------------------------------------------------------------
# Auto Scaling Outputs
# -----------------------------------------------------------------------------
output "autoscaling_target_resource_id" {
  description = "Resource ID of the auto-scaling target"
  value       = aws_appautoscaling_target.ecs.resource_id
}

# -----------------------------------------------------------------------------
# Backend URL Output
# -----------------------------------------------------------------------------
output "backend_url" {
  description = "URL of the backend API (via ALB)"
  value       = "http://${aws_lb.main.dns_name}"
}
