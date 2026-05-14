output "ec2_instance_id" {
  description = "EC2 Instance ID"
  value       = module.ec2.instance_id
}

output "ec2_public_ip" {
  description = "EC2 Public IP"
  value       = module.ec2.public_ip
}

output "cloudwatch_alarm_name" {
  description = "CloudWatch Alarm Name"
  value       = module.cloudwatch.alarm_name
}

output "lambda_function_name" {
  description = "Lambda Function Name"
  value       = module.lambda.function_name
}

output "sns_topic_arn" {
  description = "SNS Topic ARN"
  value       = module.sns.topic_arn
}
