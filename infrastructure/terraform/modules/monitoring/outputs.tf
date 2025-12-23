# -----------------------------------------------------------------------------
# Monitoring Module - Output Values
# -----------------------------------------------------------------------------
# Exports log group identifiers for use by ECS task definitions.
# -----------------------------------------------------------------------------

output "log_group_name" {
  description = "Name of the CloudWatch log group for ECS container logs"
  value       = aws_cloudwatch_log_group.ecs.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.ecs.arn
}

output "cpu_alarm_arn" {
  description = "ARN of the CPU high utilization alarm (empty if disabled)"
  value       = var.enable_alarms ? aws_cloudwatch_metric_alarm.cpu_high[0].arn : ""
}

output "memory_alarm_arn" {
  description = "ARN of the memory high utilization alarm (empty if disabled)"
  value       = var.enable_alarms ? aws_cloudwatch_metric_alarm.memory_high[0].arn : ""
}
