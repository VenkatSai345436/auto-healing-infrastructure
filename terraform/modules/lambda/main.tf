resource "aws_lambda_function" "healing_engine" {
  filename         = "healing_engine.zip"
  function_name    = "auto-healing-engine"
  role             = var.lambda_role_arn
  handler          = "healing_engine.lambda_handler"
  runtime          = "python3.11"
  timeout          = 60

  environment {
    variables = {
      INSTANCE_ID   = var.instance_id
      SNS_TOPIC_ARN = var.sns_arn
    }
  }

  tags = {
    Name    = "auto-healing-engine"
    Project = "auto-healing-infrastructure"
  }
}

# Allow EventBridge to trigger Lambda
resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.healing_engine.function_name
  principal     = "events.amazonaws.com"
}

variable "lambda_role_arn" {}
variable "instance_id" {}
variable "sns_arn" {}

output "function_name" {
  value = aws_lambda_function.healing_engine.function_name
}

output "function_arn" {
  value = aws_lambda_function.healing_engine.arn
}
