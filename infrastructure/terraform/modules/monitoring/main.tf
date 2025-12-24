# -----------------------------------------------------------------------------
# Monitoring Module - Main Configuration
# -----------------------------------------------------------------------------
# Creates CloudWatch resources for application monitoring:
# - Log group for ECS container logs with configurable retention
# - Optional metric alarms for CPU and memory utilization
#
# This module provides centralized logging for ECS Fargate containers and
# optional alerting capabilities for resource utilization monitoring.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Local Values
# -----------------------------------------------------------------------------
# Define default tags and computed values used throughout the module.
# The merged_tags combine module-specific defaults with user-provided tags.
# -----------------------------------------------------------------------------
locals {
  # Default tags applied to all resources in this module
  default_tags = {
    Name   = var.log_group_name
    Module = "monitoring"
  }

  # Merge default tags with user-provided tags (user tags take precedence)
  merged_tags = merge(local.default_tags, var.tags)
}

# -----------------------------------------------------------------------------
# CloudWatch Log Group
# -----------------------------------------------------------------------------
# Log group for ECS container logs. The awslogs driver in ECS task definitions
# sends container stdout/stderr to this log group.
#
# Default configuration:
# - Log group name: /ecs/langgraph-search-agent
# - Retention: 30 days
#
# The retention period can be adjusted based on compliance requirements and
# cost considerations. Logs older than the retention period are automatically
# deleted.
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "ecs" {
  name              = var.log_group_name
  retention_in_days = var.log_retention_days

  tags = local.merged_tags
}

# -----------------------------------------------------------------------------
# CloudWatch Metric Alarms (Optional)
# -----------------------------------------------------------------------------
# CPU and memory utilization alarms for ECS service monitoring.
# These are disabled by default and can be enabled via enable_alarms variable.
#
# When enabled, these alarms monitor the specified ECS cluster and service
# for high resource utilization and can trigger notifications via SNS.
#
# Alarm Configuration:
# - Evaluation Period: 5 minutes (300 seconds)
# - Evaluation Count: 2 consecutive periods
# - Default Thresholds: 80% for both CPU and memory
#
# The alarms will transition to ALARM state when the average utilization
# exceeds the threshold for 2 consecutive 5-minute periods.
# -----------------------------------------------------------------------------

# CPU Utilization Alarm
# Monitors average CPU utilization across all tasks in the ECS service.
# Triggers when CPU utilization exceeds the configured threshold.
resource "aws_cloudwatch_metric_alarm" "cpu" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-cpu-utilization-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_threshold
  alarm_description   = "This alarm monitors ECS CPU utilization"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions

  tags = local.merged_tags
}

# Memory Utilization Alarm
# Monitors average memory utilization across all tasks in the ECS service.
# Triggers when memory utilization exceeds the configured threshold.
resource "aws_cloudwatch_metric_alarm" "memory" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-memory-utilization-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = var.memory_threshold
  alarm_description   = "This alarm monitors ECS Memory utilization"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions

  tags = local.merged_tags
}
