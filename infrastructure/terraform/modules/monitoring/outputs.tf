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
  description = "ARN of the CPU utilization alarm (empty if alarms disabled)"
  value       = var.enable_alarms ? aws_cloudwatch_metric_alarm.cpu[0].arn : ""
}

output "memory_alarm_arn" {
  description = "ARN of the memory utilization alarm (empty if alarms disabled)"
  value       = var.enable_alarms ? aws_cloudwatch_metric_alarm.memory[0].arn : ""
}
