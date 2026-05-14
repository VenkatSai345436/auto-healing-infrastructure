# CPU Alarm — triggers if CPU > 90% for 5 consecutive minutes
resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  alarm_name          = "cpu-critical"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "5"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "90"
  alarm_description   = "Triggers when CPU stays above 90% for 5 minutes"

  dimensions = {
    InstanceId = var.instance_id
  }

  alarm_actions = [var.sns_arn]
  ok_actions    = [var.sns_arn]

  tags = {
    Name    = "cpu-critical-alarm"
    Project = "auto-healing-infrastructure"
  }
}

# Health Check Alarm — triggers if health check fails 3 times
resource "aws_cloudwatch_metric_alarm" "health_alarm" {
  alarm_name          = "healthcheck-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "0"
  alarm_description   = "Triggers when EC2 health check fails 3 times"

  dimensions = {
    InstanceId = var.instance_id
  }

  alarm_actions = [var.sns_arn]

  tags = {
    Name    = "healthcheck-alarm"
    Project = "auto-healing-infrastructure"
  }
}

# EventBridge rule — routes CloudWatch alarm to Lambda
resource "aws_cloudwatch_event_rule" "alarm_to_lambda" {
  name        = "alarm-to-healing-lambda"
  description = "Routes CloudWatch alarms to healing Lambda"

  event_pattern = jsonencode({
    source      = ["aws.cloudwatch"]
    detail-type = ["CloudWatch Alarm State Change"]
    detail = {
      state = {
        value = ["ALARM"]
      }
    }
  })
}

variable "instance_id" {}
variable "sns_arn" {}

output "alarm_name" {
  value = aws_cloudwatch_metric_alarm.cpu_alarm.alarm_name
}
