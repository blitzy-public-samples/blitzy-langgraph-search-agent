# -----------------------------------------------------------------------------
# Monitoring Module - Output Values
# -----------------------------------------------------------------------------
# This file exports CloudWatch monitoring resource identifiers for use by
# other Terraform modules and CI/CD pipelines.
#
# Outputs provided:
# - log_group_name: Name of the CloudWatch log group for ECS task definitions
# - log_group_arn: ARN of the log group for IAM policy references
# - cpu_alarm_arn: ARN of CPU utilization alarm (null if disabled)
# - memory_alarm_arn: ARN of Memory utilization alarm (null if disabled)
#
# These outputs integrate with:
# - ECS Fargate module: Uses log_group_name for awslogs-group configuration
# - IAM module: Uses log_group_arn for granting log write permissions
# - SNS/alerting systems: Use alarm ARNs for notification routing
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Log Group Outputs
# -----------------------------------------------------------------------------
# The log group outputs are used by the ECS task definition to configure
# container logging via the awslogs driver. The log group name is required
# in the logConfiguration block, while the ARN is used for IAM permissions.
# -----------------------------------------------------------------------------

output "log_group_name" {
  description = "The name of the CloudWatch log group for ECS container logs"
  value       = aws_cloudwatch_log_group.ecs.name
}

output "log_group_arn" {
  description = "The ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.ecs.arn
}

# -----------------------------------------------------------------------------
# Alarm Outputs (Conditional)
# -----------------------------------------------------------------------------
# Alarm outputs are conditional based on the enable_alarms variable.
# When alarms are disabled (default), these outputs return null.
# When alarms are enabled, these outputs return the alarm ARNs which can be
# used for integration with SNS topics or other alerting mechanisms.
#
# Usage example in parent module:
#   resource "aws_sns_topic_subscription" "cpu_alert" {
#     count     = module.monitoring.cpu_alarm_arn != null ? 1 : 0
#     topic_arn = aws_sns_topic.alerts.arn
#     protocol  = "email"
#     endpoint  = "alerts@example.com"
#   }
# -----------------------------------------------------------------------------

output "cpu_alarm_arn" {
  description = "The ARN of the CPU utilization alarm"
  value       = var.enable_alarms ? aws_cloudwatch_metric_alarm.cpu[0].arn : null
}

output "memory_alarm_arn" {
  description = "The ARN of the Memory utilization alarm"
  value       = var.enable_alarms ? aws_cloudwatch_metric_alarm.memory[0].arn : null
}
