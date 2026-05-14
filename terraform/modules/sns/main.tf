# SNS Topic — receives CloudWatch alarms
resource "aws_sns_topic" "healing_topic" {
  name = "auto-healing-alerts"

  tags = {
    Name    = "auto-healing-alerts"
    Project = "auto-healing-infrastructure"
  }
}

# SNS Subscription — triggers Lambda
resource "aws_sns_topic_subscription" "lambda_trigger" {
  topic_arn = aws_sns_topic.healing_topic.arn
  protocol  = "lambda"
  endpoint  = var.lambda_arn
}

variable "slack_webhook" {}
variable "lambda_arn" {
  default = ""
}

output "topic_arn" {
  value = aws_sns_topic.healing_topic.arn
}
