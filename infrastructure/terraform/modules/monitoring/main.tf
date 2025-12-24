# -----------------------------------------------------------------------------
# Monitoring Module - Main Configuration
# -----------------------------------------------------------------------------
# Creates CloudWatch resources for application monitoring:
# - Log group for ECS container logs
# - Optional metric alarms for CPU and memory utilization
# -----------------------------------------------------------------------------

locals {
  default_tags = {
    Module = "monitoring"
  }
  merged_tags = merge(local.default_tags, var.tags)

  # Use provided log group name or generate from project name
  log_group_name = var.log_group_name != "" ? var.log_group_name : "/ecs/${var.project_name}"
}

# -----------------------------------------------------------------------------
# CloudWatch Log Group
# -----------------------------------------------------------------------------
# Log group for ECS container logs. The awslogs driver in ECS task definitions
# sends container stdout/stderr to this log group.
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "ecs" {
  name              = local.log_group_name
  retention_in_days = var.log_retention_days

  tags = merge(local.merged_tags, {
    Name = local.log_group_name
  })
}

# -----------------------------------------------------------------------------
# CloudWatch Metric Alarms (Optional)
# -----------------------------------------------------------------------------
# CPU and memory utilization alarms for ECS service monitoring.
# These are disabled by default and can be enabled via enable_alarms variable.
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.cpu_threshold
  alarm_description   = "ECS CPU utilization is above ${var.cpu_threshold}%"
  treat_missing_data  = var.treat_missing_data
  datapoints_to_alarm = var.alarm_datapoints_to_alarm

  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions

  dimensions = {
    ClusterName = var.ecs_cluster_name != "" ? var.ecs_cluster_name : "${var.project_name}-cluster"
    ServiceName = var.ecs_service_name != "" ? var.ecs_service_name : "${var.project_name}-service"
  }

  tags = local.merged_tags
}

resource "aws_cloudwatch_metric_alarm" "memory_high" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.memory_threshold
  alarm_description   = "ECS memory utilization is above ${var.memory_threshold}%"
  treat_missing_data  = var.treat_missing_data
  datapoints_to_alarm = var.alarm_datapoints_to_alarm

  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions

  dimensions = {
    ClusterName = var.ecs_cluster_name != "" ? var.ecs_cluster_name : "${var.project_name}-cluster"
    ServiceName = var.ecs_service_name != "" ? var.ecs_service_name : "${var.project_name}-service"
  }

  tags = local.merged_tags
}
