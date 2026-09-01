################################################################################
# modules/monitoring/main.tf
# Sets up CloudWatch monitoring for EC2, RDS, and ALB.
# No extra tools — uses AWS-native services only.
################################################################################

# ── IAM Role for CloudWatch Agent on EC2 ─────────────────────────────────────
# Gives EC2 permission to push logs and metrics to CloudWatch

resource "aws_iam_role" "cloudwatch_agent" {
  name = "${var.project_name}-cloudwatch-agent-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.cloudwatch_agent.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "cloudwatch_agent" {
  name = "${var.project_name}-cloudwatch-agent-profile"
  role = aws_iam_role.cloudwatch_agent.name
}

# ── CloudWatch Log Groups ─────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/desk-analytics/application"
  retention_in_days = 7
  tags = { Name = "application-logs" }
}

resource "aws_cloudwatch_log_group" "system_logs" {
  name              = "/desk-analytics/system"
  retention_in_days = 7
  tags = { Name = "system-logs" }
}

resource "aws_cloudwatch_log_group" "access_logs" {
  name              = "/desk-analytics/access"
  retention_in_days = 7
  tags = { Name = "access-logs" }
}

# ── CloudWatch Alarms ─────────────────────────────────────────────────────────

# EC2 — High CPU
resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  alarm_name          = "${var.project_name}-high-cpu"
  alarm_description   = "EC2 CPU utilization above 80%"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  dimensions          = { InstanceId = var.ec2_instance_id }
}

# RDS — High CPU
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.project_name}-rds-high-cpu"
  alarm_description   = "RDS CPU utilization above 80%"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  dimensions          = { DBInstanceIdentifier = var.rds_identifier }
}

# RDS — Low Storage
resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "${var.project_name}-rds-low-storage"
  alarm_description   = "RDS free storage below 2GB"
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 1
  threshold           = 2000000000
  comparison_operator = "LessThanThreshold"
  dimensions          = { DBInstanceIdentifier = var.rds_identifier }
}

# ALB — High Error Rate (5xx)
resource "aws_cloudwatch_metric_alarm" "alb_errors" {
  alarm_name          = "${var.project_name}-alb-5xx-errors"
  alarm_description   = "ALB 5xx error count above 10 in 5 minutes"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 10
  comparison_operator = "GreaterThanThreshold"
  dimensions          = { LoadBalancer = var.alb_arn_suffix }
}

# ── Dashboard 1: Infrastructure ───────────────────────────────────────────────
resource "aws_cloudwatch_dashboard" "infrastructure" {
  dashboard_name = "${var.project_name}-infrastructure"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x = 0
        y = 0
        width = 12
        height = 6
        properties = {
          title   = "EC2 CPU Utilization (%)"
          view    = "timeSeries"
          region  = var.aws_region
          period  = 300
          stat    = "Average"
          metrics = [["AWS/EC2", "CPUUtilization", "InstanceId", var.ec2_instance_id]]
        }
      },
      {
        type   = "metric"
        x = 12
        y = 0
        width = 12
        height = 6
        properties = {
          title   = "EC2 Network In/Out (Bytes)"
          view    = "timeSeries"
          region  = var.aws_region
          period  = 300
          stat    = "Average"
          metrics = [
            ["AWS/EC2", "NetworkIn",  "InstanceId", var.ec2_instance_id],
            ["AWS/EC2", "NetworkOut", "InstanceId", var.ec2_instance_id]
          ]
        }
      },
      {
        type   = "metric"
        x = 0
        y = 6
        width = 12
        height = 6
        properties = {
          title   = "RDS CPU Utilization (%)"
          view    = "timeSeries"
          region  = var.aws_region
          period  = 300
          stat    = "Average"
          metrics = [["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.rds_identifier]]
        }
      },
      {
        type   = "metric"
        x = 12
        y = 6
        width = 12
        height = 6
        properties = {
          title   = "RDS Free Storage (Bytes)"
          view    = "timeSeries"
          region  = var.aws_region
          period  = 300
          stat    = "Average"
          metrics = [["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", var.rds_identifier]]
        }
      },
      {
        type   = "metric"
        x = 0
        y = 12
        width = 12
        height = 6
        properties = {
          title   = "RDS Database Connections"
          view    = "timeSeries"
          region  = var.aws_region
          period  = 300
          stat    = "Average"
          metrics = [["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.rds_identifier]]
        }
      },
      {
        type   = "alarm"
        x = 12
        y = 12
        width = 12
        height = 6
        properties = {
          title  = "Active Alarms"
          region = var.aws_region
          alarms = [
            aws_cloudwatch_metric_alarm.ec2_cpu.arn,
            aws_cloudwatch_metric_alarm.rds_cpu.arn,
            aws_cloudwatch_metric_alarm.rds_storage.arn
          ]
        }
      }
    ]
  })
}

# ── Dashboard 2: Application ──────────────────────────────────────────────────
resource "aws_cloudwatch_dashboard" "application" {
  dashboard_name = "${var.project_name}-application"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x = 0
        y = 0
        width = 12
        height = 6
        properties = {
          title   = "ALB Request Rate (per 5 min)"
          view    = "timeSeries"
          region  = var.aws_region
          period  = 300
          stat    = "Sum"
          metrics = [["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix]]
        }
      },
      {
        type   = "metric"
        x = 12
        y = 0
        width = 12
        height = 6
        properties = {
          title   = "ALB Response Time (seconds)"
          view    = "timeSeries"
          region  = var.aws_region
          period  = 300
          stat    = "Average"
          metrics = [["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix]]
        }
      },
      {
        type   = "metric"
        x = 0
        y = 6
        width = 12
        height = 6
        properties = {
          title   = "ALB HTTP Response Codes"
          view    = "timeSeries"
          region  = var.aws_region
          period  = 300
          stat    = "Sum"
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "LoadBalancer", var.alb_arn_suffix, { label = "2xx Success" }],
            ["AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "LoadBalancer", var.alb_arn_suffix, { label = "4xx Client Error" }],
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count",   "LoadBalancer", var.alb_arn_suffix, { label = "5xx Server Error" }]
          ]
        }
      },
      {
        type   = "metric"
        x = 12
        y = 6
        width = 12
        height = 6
        properties = {
          title   = "ALB Target Health"
          view    = "timeSeries"
          region  = var.aws_region
          period  = 60
          stat    = "Average"
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount",   "LoadBalancer", var.alb_arn_suffix, { label = "Healthy" }],
            ["AWS/ApplicationELB", "UnHealthyHostCount", "LoadBalancer", var.alb_arn_suffix, { label = "Unhealthy" }]
          ]
        }
      },
      {
        type   = "log"
        x = 0
        y = 12
        width = 24
        height = 6
        properties = {
          title  = "Recent Application Errors"
          view   = "table"
          region = var.aws_region
          query  = "SOURCE '/desk-analytics/application' | fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 20"
        }
      }
    ]
  })
}
