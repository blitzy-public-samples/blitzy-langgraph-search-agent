# -----------------------------------------------------------------------------
# Monitoring Module - Input Variables
# -----------------------------------------------------------------------------
# This file defines all input variables for the CloudWatch monitoring module.
# The module configures log groups for ECS container logging and optional
# metric alarms for CPU and memory utilization monitoring.
#
# Variable Naming Conventions:
# - Use snake_case for all variable names
# - Provide descriptive descriptions for each variable
# - Include validation blocks where appropriate
# - Set sensible defaults where possible
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Log Group Configuration
# -----------------------------------------------------------------------------

variable "log_group_name" {
  description = "Name of the CloudWatch log group for ECS container logs. Must match the awslogs-group configuration in the ECS task definition."
  type        = string
  default     = "/ecs/langgraph-search-agent"

  validation {
    condition     = can(regex("^[a-zA-Z0-9_/.-]+$", var.log_group_name))
    error_message = "Log group name must contain only alphanumeric characters, underscores, hyphens, forward slashes, and periods."
  }
}

variable "log_retention_days" {
  description = "Number of days to retain log events in the CloudWatch log group. Valid values are: 0 (never expire), 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653."
  type        = number
  default     = 30

  validation {
    condition = contains([
      0,    # Never expire
      1,    # 1 day
      3,    # 3 days
      5,    # 5 days
      7,    # 1 week
      14,   # 2 weeks
      30,   # 1 month
      60,   # 2 months
      90,   # 3 months
      120,  # 4 months
      150,  # 5 months
      180,  # 6 months
      365,  # 1 year
      400,  # 13 months
      545,  # 18 months
      731,  # 2 years
      1096, # 3 years
      1827, # 5 years
      2192, # 6 years
      2557, # 7 years
      2922, # 8 years
      3288, # 9 years
      3653  # 10 years
    ], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch Logs retention period: 0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, or 3653."
  }
}

# -----------------------------------------------------------------------------
# Project Naming Configuration
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Project name used for resource naming and identification. This value is used as a prefix or suffix in resource names to ensure uniqueness and traceability."
  type        = string
  default     = "langgraph-search-agent"

  validation {
    condition     = length(var.project_name) > 0 && length(var.project_name) <= 63
    error_message = "Project name must be between 1 and 63 characters long."
  }

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.project_name))
    error_message = "Project name must contain only alphanumeric characters and hyphens."
  }
}

# -----------------------------------------------------------------------------
# Alarm Configuration
# -----------------------------------------------------------------------------

variable "enable_alarms" {
  description = "Enable CloudWatch metric alarms for ECS CPU and memory utilization monitoring. When enabled, alarms will be created based on the threshold configurations. Disabled by default to minimize costs in development environments."
  type        = bool
  default     = false
}

variable "cpu_threshold" {
  description = "CPU utilization threshold percentage for alarm trigger. The alarm fires when the average CPU utilization exceeds this percentage over the evaluation period. Value must be between 1 and 100."
  type        = number
  default     = 80

  validation {
    condition     = var.cpu_threshold >= 1 && var.cpu_threshold <= 100
    error_message = "CPU threshold must be between 1 and 100 percent."
  }
}

variable "memory_threshold" {
  description = "Memory utilization threshold percentage for alarm trigger. The alarm fires when the average memory utilization exceeds this percentage over the evaluation period. Value must be between 1 and 100."
  type        = number
  default     = 80

  validation {
    condition     = var.memory_threshold >= 1 && var.memory_threshold <= 100
    error_message = "Memory threshold must be between 1 and 100 percent."
  }
}

# -----------------------------------------------------------------------------
# ECS Dimensions for Alarms
# -----------------------------------------------------------------------------

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster for alarm dimensions. Required when enable_alarms is true. This value is used as the ClusterName dimension in CloudWatch metrics."
  type        = string
  default     = ""

  validation {
    condition     = var.ecs_cluster_name == "" || can(regex("^[a-zA-Z0-9_-]+$", var.ecs_cluster_name))
    error_message = "ECS cluster name must contain only alphanumeric characters, underscores, and hyphens."
  }
}

variable "ecs_service_name" {
  description = "Name of the ECS service for alarm dimensions. Required when enable_alarms is true. This value is used as the ServiceName dimension in CloudWatch metrics."
  type        = string
  default     = ""

  validation {
    condition     = var.ecs_service_name == "" || can(regex("^[a-zA-Z0-9_-]+$", var.ecs_service_name))
    error_message = "ECS service name must contain only alphanumeric characters, underscores, and hyphens."
  }
}

# -----------------------------------------------------------------------------
# Alarm Notification Configuration
# -----------------------------------------------------------------------------

variable "alarm_actions" {
  description = "List of ARNs to notify when an alarm transitions to the ALARM state. Typically SNS topic ARNs that send notifications to email, SMS, Slack, or PagerDuty. Leave empty if no notifications are required."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for arn in var.alarm_actions : can(regex("^arn:aws:", arn))])
    error_message = "All alarm actions must be valid AWS ARNs starting with 'arn:aws:'."
  }
}

variable "ok_actions" {
  description = "List of ARNs to notify when an alarm transitions from ALARM to OK state. Typically SNS topic ARNs for recovery notifications. Using the same SNS topics as alarm_actions is common practice."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for arn in var.ok_actions : can(regex("^arn:aws:", arn))])
    error_message = "All OK actions must be valid AWS ARNs starting with 'arn:aws:'."
  }
}

# -----------------------------------------------------------------------------
# Resource Tagging
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Tags to apply to all monitoring resources. These tags are merged with common_tags passed from the root module. Standard tags should include Project, Environment, ManagedBy, and Region."
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Advanced Alarm Configuration (Optional)
# -----------------------------------------------------------------------------

variable "alarm_evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold. Each period is defined by alarm_period_seconds. A value of 2 with a 300-second period means the alarm evaluates 10 minutes of data."
  type        = number
  default     = 2

  validation {
    condition     = var.alarm_evaluation_periods >= 1 && var.alarm_evaluation_periods <= 1440
    error_message = "Alarm evaluation periods must be between 1 and 1440."
  }
}

variable "alarm_period_seconds" {
  description = "The period in seconds over which the specified statistic is applied. Valid values are multiples of 60. Common values: 60 (1 minute), 300 (5 minutes), 900 (15 minutes)."
  type        = number
  default     = 300

  validation {
    condition     = var.alarm_period_seconds >= 60 && var.alarm_period_seconds % 60 == 0
    error_message = "Alarm period must be at least 60 seconds and a multiple of 60."
  }
}

variable "alarm_datapoints_to_alarm" {
  description = "The number of datapoints that must be breaching to trigger the alarm. Must be less than or equal to alarm_evaluation_periods. For example, setting this to 2 with 3 evaluation periods means 2 out of 3 periods must breach the threshold."
  type        = number
  default     = 2

  validation {
    condition     = var.alarm_datapoints_to_alarm >= 1
    error_message = "Datapoints to alarm must be at least 1."
  }
}

variable "treat_missing_data" {
  description = "How to handle missing data points when evaluating the alarm. Valid values: 'missing' (alarm doesn't consider missing data), 'notBreaching' (treat as within threshold), 'breaching' (treat as outside threshold), 'ignore' (maintain current state)."
  type        = string
  default     = "missing"

  validation {
    condition     = contains(["missing", "notBreaching", "breaching", "ignore"], var.treat_missing_data)
    error_message = "Treat missing data must be one of: missing, notBreaching, breaching, or ignore."
  }
}
