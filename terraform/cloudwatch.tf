
# ============================================================
# SNS - Email Alerts
# ============================================================

resource "aws_sns_topic" "alerts" {
  name = "depi-sec-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ============================================================
# Alarm 1 - EC2 CPU Utilization
# One alarm covers both EC2 instances using metric math.
# ============================================================

resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  alarm_name        = "depi-sec-ec2-high-cpu"
  alarm_description = "Maximum EC2 CPU utilization above 70% for two consecutive 5-minute periods."

  comparison_operator = "GreaterThanThreshold"
  threshold           = 70
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  treat_missing_data  = "missing"

  metric_query {
    id          = "cpu_max"
    expression  = "MAX([cpu1,cpu2])"
    label       = "Maximum EC2 CPU Utilization"
    return_data = true
  }

  metric_query {
    id          = "cpu1"
    return_data = false

    metric {
      namespace   = "AWS/EC2"
      metric_name = "CPUUtilization"
      period      = 300
      stat        = "Average"

      dimensions = {
        InstanceId = aws_instance.web_az1.id
      }
    }
  }

  metric_query {
    id          = "cpu2"
    return_data = false

    metric {
      namespace   = "AWS/EC2"
      metric_name = "CPUUtilization"
      period      = 300
      stat        = "Average"

      dimensions = {
        InstanceId = aws_instance.web_az2.id
      }
    }
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# ============================================================
# Alarm 2 - ALB Unhealthy Hosts
# ============================================================

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy" {
  alarm_name          = "depi-sec-alb-unhealthy-hosts"
  alarm_description   = "Alarm when one or more ALB targets are unhealthy."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "missing"

  dimensions = {
    LoadBalancer = aws_lb.app.arn_suffix
    TargetGroup  = aws_lb_target_group.app.arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# ============================================================
# Alarm 3 - RDS Free Storage
# 2 GiB = 2147483648 bytes
# ============================================================

resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "depi-sec-rds-low-storage"
  alarm_description   = "Alarm when RDS free storage falls below 2 GiB."
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  statistic           = "Minimum"
  period              = 300
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 2147483648
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "missing"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.mysql.identifier
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# ============================================================
# Alarm 4 - Failed AWS Console Login
# CloudTrail must deliver events to its CloudWatch Log Group.
# ============================================================

resource "aws_cloudwatch_log_metric_filter" "failed_console_login" {
  name           = "depi-sec-failed-console-login"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  pattern = "{ ($.eventName = \"ConsoleLogin\") && ($.errorMessage = \"Failed authentication\") }"

  metric_transformation {
    name          = "FailedConsoleLoginCount"
    namespace     = "DEPI/Security"
    value         = "1"
    default_value = 0
  }
}

resource "aws_cloudwatch_metric_alarm" "failed_console_login" {
  alarm_name          = "depi-sec-failed-console-logins"
  alarm_description   = "Alarm after 3 failed ConsoleLogin authentication events in 5 minutes."
  namespace           = "DEPI/Security"
  metric_name         = "FailedConsoleLoginCount"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 3
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  depends_on = [aws_cloudwatch_log_metric_filter.failed_console_login]
}

# ============================================================
# CloudWatch Dashboard - Four Widgets
# ============================================================

resource "aws_cloudwatch_dashboard" "overview" {
  dashboard_name = "depi-sec-overview"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "EC2 CPU Utilization"
          region = var.region
          view   = "timeSeries"
          period = 300
          stat   = "Average"

          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.web_az1.id, { label = "EC2 AZ1" }],
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.web_az2.id, { label = "EC2 AZ2" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "ALB Unhealthy Hosts"
          region = var.region
          view   = "timeSeries"
          period = 60
          stat   = "Maximum"

          metrics = [
            [
              "AWS/ApplicationELB",
              "UnHealthyHostCount",
              "LoadBalancer",
              aws_lb.app.arn_suffix,
              "TargetGroup",
              aws_lb_target_group.app.arn_suffix
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "RDS Free Storage (Bytes)"
          region = var.region
          view   = "timeSeries"
          period = 300
          stat   = "Minimum"

          metrics = [
            [
              "AWS/RDS",
              "FreeStorageSpace",
              "DBInstanceIdentifier",
              aws_db_instance.mysql.identifier
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "Failed Console Logins"
          region = var.region
          view   = "timeSeries"
          period = 300
          stat   = "Sum"

          metrics = [
            [
              "DEPI/Security",
              "FailedConsoleLoginCount"
            ]
          ]
        }
      }
    ]
  })
}
